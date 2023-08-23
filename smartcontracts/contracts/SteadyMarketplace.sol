// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*
 * @title SteadyMarketplace
 * @description A marketplace for CryptoCities "baskets" of good and services in the ecosystem,
 * which acts as a data source for the SteadyEngine contract.
 * @author ricogustavo
 * @team Futurify x EpicStartups
 *
 */

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {OrderSet} from "./libraries/OrderSet.sol";

contract SteadyMarketplace is Context, Ownable {
    error SteadyMarketplace__OnlyVendor();
    error SteadyMarketplace__VendorFeeNotPaid();
    error SteadyMarketplace__VendorHasNotCreatedCollection();
    error SteadyMarketplace__CollectionDoesNotExist();
    error SteadyMarketplace__InsufficientBalance();
    error SteadyMarketplace__CallerHasNotApprovedContractForTokenTransfer();
    error SteadyMarketplace__CallerDoesNotOwnToken();
    error SteadyMarketplace__TokenIsNotListedForSaleByTheOwner();
    error SteadyMarketplace__AttemptingToBuyMoreThanAvailableForSale();
    error SteadyMarketplace__LessETHProvidedForThePurchase();
    error SteadyMarketplace__SellerHasRemovedContractsApprovalForTokenTransfer();
    error SteadyMarketplace__FailedToSendEtherToTheTokenOwner();
    error SteadyMarketplace__FailedToSendEtherToTheVendor();
    error SteadyMarketplace__FailedToSendEtherToTheOwner();

    // Use SafeMath library for uint256 arithmetic operations
    using SafeMath for uint256;
    // Use OrderSet for OrderSet.Set operations
    using OrderSet for OrderSet.Set;

    // charge a fee of 100 MATIC equivalent to become a vendor
    uint256 public constant VENDOR_FEE = 100 ether; // TODO: update vendor fee charge - to be revised

    // Mapping to store sell orders for different NFTs
    mapping(bytes32 => OrderSet.Set) private orders;

    // Vendor data structure to store vendor details
    struct Vendor {
        address vendorAddress; // TODO: create a new contract for each vendor
        string vendorName;
        string vendorDescription;
        VendorCollection[] vendorCollections;
        uint256 dateCreated;
        uint256 dateUpdated;
    }
    // VendorCollection data structure to store vendor collection details
    struct VendorCollection {
        uint256 collectionId;
        address collectionAddress; // TODO: create a new contract for each collection
        OrderSet.Category category;
        string collectionName;
        string collectionDescription;
        uint256 collectionTotalSales;
        uint256 collectionTotalSalesByCategory;
        uint256 dateCreated;
        uint256 dateUpdated;
    }

    // Mapping to store vendor details
    mapping(address => VendorCollection) public vendorCollections;

    // Mapping to store vendor details
    mapping(address => Vendor) public vendors;

    // Event to indicate a token is listed for sale
    event ListedForSale(
        // Account address of the token owner
        address account,
        // NFT id
        uint256 nftId,
        // Contract address of the NFT
        address nftContract,
        // Number of tokens for sale
        uint256 noOfTokensForSale,
        // Unit price of each token
        uint256 unitPrice,
        // Category of the NFT
        OrderSet.Category category,
        // Date when the NFT was created
        uint256 date
    );

    // Event to indicate a token is unlisted from sale
    event UnlistedFromSale(
        // Account address of the token owner
        address account,
        // NFT id
        uint256 nftId,
        // Contract address of the NFT
        address nftContract
    );

    // Event to indicate a token is sold
    event TokensSold(
        // Account address of the token seller
        address from,
        // Account address of the token buyer
        address to,
        // NFT id
        uint256 nftId,
        // Contract address of the NFT
        address nftContract,
        // Number of tokens sold
        uint256 tokenCount,
        // Purchase amount
        uint256 puchaseAmount
    );

    // Event when new vendor is created
    event VendorCreated(
        // Account address of the vendor
        address account,
        // Name of the vendor
        string name,
        // Description of the vendor
        string description,
        // Date when the vendor was created
        uint256 dateCreated,
        // Date when the vendor was updated
        uint256 dateUpdated
    );

    // Event when vendor is updated
    event VendorUpdated(
        // Account address of the vendor
        address account,
        // Name of the vendor
        string name,
        // Description of the vendor
        string description,
        // Date when the vendor was updated
        uint256 dateUpdated
    );

    // Event when new vendor collection is created
    event VendorCollectionCreated(
        // Account address of the vendor
        address vendorAddress,
        // Collection id of the vendor
        uint256 collectionId,
        // Collection address of the vendor
        address collectionAddress,
        // Name of the vendor
        string vendorName,
        // Description of the vendor
        string vendorDescription,
        // Date when the vendor was created
        uint256 dateCreated,
        // Date when the vendor was updated
        uint256 dateUpdated
    );

    // Event when vendor collection is updated
    event VendorCollectionUpdated(
        // Account address of the vendor
        address vendorAddress,
        // Collection id of the vendor
        uint256 collectionId,
        // Collection address of the vendor
        address collectionAddress,
        // Name of the vendor
        string vendorName,
        // Description of the vendor
        string vendorDescription,
        // Date when the vendor was updated
        uint256 dateUpdated
    );

    // modifier to check if the caller is a vendor
    modifier onlyVendor() {
        if (vendors[_msgSender()].vendorAddress != _msgSender()) {
            revert SteadyMarketplace__OnlyVendor();
        }
        _;
    }

    // modifier to check if the user paid the vendor fee
    modifier paidVendorFee() {
        if (msg.value != VENDOR_FEE) {
            revert SteadyMarketplace__VendorFeeNotPaid();
        }
        _;
    }

    // modifier to check if the vendor has created a collection
    modifier hasCreatedCollection() {
        if (vendors[_msgSender()].vendorCollections.length == 0) {
            revert SteadyMarketplace__VendorHasNotCreatedCollection();
        }
        _;
    }

    // modifier to check if the collection is valid
    modifier validCollection(address collectionAddress) {
        if (
            vendorCollections[collectionAddress].collectionAddress !=
            collectionAddress
        ) {
            revert SteadyMarketplace__CollectionDoesNotExist();
        }
        _;
    }

    // modifier to check if the vendor has sufficient balance
    modifier sufficientVendorBalance(
        address collectionAddress,
        uint256 amount
    ) {
        if (
            vendorCollections[collectionAddress].collectionTotalSales < amount
        ) {
            revert SteadyMarketplace__InsufficientBalance();
        }
        _;
    }

    // modifier to check if owner has sufficient balance
    modifier sufficientOwnerBalance(uint256 amount) {
        if (address(this).balance < amount) {
            revert SteadyMarketplace__InsufficientBalance();
        }
        _;
    }

    /**
     * registerVendor - Registers a new vendor
     * @param name - Name of the vendor
     * @param description - Description of the vendor
     */
    function registerVendor(
        string memory name,
        string memory description
    ) external payable paidVendorFee {
        uint256 newDate = block.timestamp;
        // Create a new vendor with push
        Vendor memory v = Vendor(
            _msgSender(),
            name,
            description,
            new VendorCollection[](0),
            newDate,
            newDate
        );

        // Add the vendor to the vendors mapping
        vendors[_msgSender()] = v;

        // Emit the VendorCreated event
        emit VendorCreated(_msgSender(), name, description, newDate, newDate);
    }

    /**
     * registerVendorCollection - Registers a new vendor collection
     * @param collectionId - Collection id of the vendor
     * @param collectionAddress - Collection address of the vendor
     * @param category - Category of the vendor
     * @param name - Name of the vendor
     * @param description - Description of the vendor
     */
    function registerVendorCollection(
        uint256 collectionId,
        address collectionAddress,
        OrderSet.Category category,
        string memory name,
        string memory description
    ) external payable onlyVendor {
        uint256 newDate = block.timestamp;
        // Create a new vendor collection with push
        VendorCollection memory vc = VendorCollection(
            collectionId,
            collectionAddress,
            category,
            name,
            description,
            0,
            0,
            newDate,
            newDate
        );

        // Add the vendor collection to the vendor collections mapping
        vendorCollections[collectionAddress] = vc;

        // Add the vendor collection to the vendor's vendorCollections array
        vendors[_msgSender()].vendorCollections.push(vc);

        // Emit the VendorCollectionCreated event
        emit VendorCollectionCreated(
            _msgSender(),
            collectionId,
            collectionAddress,
            name,
            description,
            newDate,
            newDate
        );
    }

    /**
     * updateVendor - Updates an existing vendor
     * @param name - Name of the vendor
     * @param description - Description of the vendor
     */
    function updateVendor(
        string memory name,
        string memory description
    ) external payable onlyVendor {
        uint256 newDate = block.timestamp;

        vendors[_msgSender()].vendorName = name;
        vendors[_msgSender()].vendorDescription = description;
        vendors[_msgSender()].dateUpdated = newDate;

        emit VendorUpdated(_msgSender(), name, description, newDate);
    }

    /**
     * updateVendorCollection - Updates an existing vendor collection
     * @param collectionAddress - Address of the vendor collection
     * @param name - Name of the vendor collection
     * @param description - Description of the vendor collection
     */

    function updateVendorCollection(
        address collectionAddress,
        string memory name,
        string memory description
    ) external payable onlyVendor validCollection(collectionAddress) {
        uint256 newDate = block.timestamp;
        vendorCollections[collectionAddress].collectionName = name;
        vendorCollections[collectionAddress]
            .collectionDescription = description;
        vendorCollections[collectionAddress].dateUpdated = newDate;

        emit VendorCollectionUpdated(
            _msgSender(),
            vendorCollections[collectionAddress].collectionId,
            collectionAddress,
            name,
            description,
            newDate
        );
    }

    /**
     * createSellOrder - Creates a sell order for the NFT specified by `nftId` and `contractAddress`.
     *
     * @param nftId          - The ID of the NFT to be sold.
     * @param contractAddress - The address of the NFT's contract.
     * @param nftType        - The type of the NFT, either 'erc721' or 'erc1155'.
     * @param unitPrice      - The price of a single NFT in wei.
     * @param noOfTokensForSale - The number of NFTs being sold.
     * @param category       - The category of the NFT.
     */

    function createSellOrder(
        uint256 nftId,
        address contractAddress,
        string memory nftType,
        uint256 unitPrice,
        uint256 noOfTokensForSale,
        OrderSet.Category category
    ) external onlyVendor hasCreatedCollection {
        if (unitPrice <= 0) {
            revert SteadyMarketplace__InsufficientBalance();
        }

        // Get the unique identifier for the sell order
        bytes32 orderId = _getOrdersMapId(nftId, contractAddress);

        // Get the sell order set for the given NFT
        OrderSet.Set storage nftOrders = orders[orderId];

        // Require that the token is not already listed for sale by the same owner
        if (nftOrders.orderExistsForAddress(_msgSender())) {
            revert SteadyMarketplace__InsufficientBalance();
        }

        // Check if the NFT token is an ERC721 or ERC1155 token
        if (
            keccak256(abi.encodePacked(nftType)) ==
            keccak256(abi.encodePacked("erc721"))
        ) {
            // Get the ERC721 contract
            IERC721 tokenContract = IERC721(contractAddress);

            // Require that the caller has approved the contract for token transfer
            if (!tokenContract.isApprovedForAll(_msgSender(), address(this))) {
                revert SteadyMarketplace__CallerHasNotApprovedContractForTokenTransfer();
            }

            // Require that the caller owns the NFT token
            if (tokenContract.ownerOf(nftId) != _msgSender()) {
                revert SteadyMarketplace__CallerDoesNotOwnToken();
            }
        } else if (
            keccak256(abi.encodePacked(nftType)) ==
            keccak256(abi.encodePacked("erc1155"))
        ) {
            // Get the ERC1155 contract
            IERC1155 tokenContract = IERC1155(contractAddress);

            // Require that the caller has approved the contract for token transfer
            if (!tokenContract.isApprovedForAll(_msgSender(), address(this))) {
                revert SteadyMarketplace__CallerHasNotApprovedContractForTokenTransfer();
            }

            // Require that the caller has sufficient balance of the NFT token
            if (
                tokenContract.balanceOf(_msgSender(), nftId) < noOfTokensForSale
            ) {
                revert SteadyMarketplace__InsufficientBalance();
            }
        } else {
            // Revert if the NFT token is not of type ERC721 or ERC1155
            revert("Unsupported token type.");
        }

        uint256 newDate = block.timestamp;

        // Create a new sell order using the SellOrder constructor
        OrderSet.SellOrder memory o = OrderSet.SellOrder(
            _msgSender(),
            noOfTokensForSale,
            unitPrice,
            OrderSet.Category(category),
            newDate
        );
        nftOrders.insert(o);

        // Emit the 'ListedForSale' event to signal that a new NFT has been listed for sale
        emit ListedForSale(
            _msgSender(),
            nftId,
            contractAddress,
            noOfTokensForSale,
            unitPrice,
            category,
            newDate
        );
    }

    /**
     * cancelSellOrder - Cancels the sell order created by the caller for a specific NFT token.
     *
     * @param nftId ID of the NFT token to cancel the sell order for.
     * @param contractAddress Address of the NFT contract for the NFT token.
     */
    function cancelSellOrder(
        uint256 nftId,
        address contractAddress
    ) external onlyVendor hasCreatedCollection {
        // Get the unique identifier for the order set of the given NFT token.
        bytes32 orderId = _getOrdersMapId(nftId, contractAddress);

        // Get the sell order set of the given NFT token.
        OrderSet.Set storage nftOrders = orders[orderId];

        // Ensure that the sell order exists for the caller.
        if (!nftOrders.orderExistsForAddress(_msgSender())) {
            revert SteadyMarketplace__TokenIsNotListedForSaleByTheOwner();
        }

        // Remove the sell order from the set.
        nftOrders.remove(nftOrders.orderByAddress(_msgSender()));

        // Emit an event indicating that the sell order has been unlisted.
        emit UnlistedFromSale(_msgSender(), nftId, contractAddress);
    }

    /**
     * createBuyOrder - Create a buy order for an NFT token.
     *
     * @param nftId - unique identifier of the NFT token.
     * @param contractAddress - address of the NFT contract that holds the token.
     * @param nftType - type of the NFT token, either 'erc721' or 'erc1155'.
     * @param noOfTokensToBuy - number of tokens the buyer wants to purchase.
     * @param tokenOwner - address of the seller who is selling the token.
     */

    function createBuyOrder(
        uint256 nftId,
        address contractAddress,
        string memory nftType, // 'erc721' or 'erc1155'
        uint256 noOfTokensToBuy,
        address payable tokenOwner
    ) external payable {
        // Get the unique identifier for the order set of the given NFT token.
        bytes32 orderId = _getOrdersMapId(nftId, contractAddress);

        // Get the sell order set of the given NFT token.
        OrderSet.Set storage nftOrders = orders[orderId];

        // Check if the token owner has a sell order for the given NFT.
        if (!nftOrders.orderExistsForAddress(tokenOwner)) {
            revert SteadyMarketplace__TokenIsNotListedForSaleByTheOwner();
        }

        // Get the sell order for the given NFT by the token owner.
        OrderSet.SellOrder storage sellOrder = nftOrders.orderByAddress(
            tokenOwner
        );

        // Validate that the required buy quantity is available for sale
        if (sellOrder.quantity < noOfTokensToBuy) {
            revert SteadyMarketplace__AttemptingToBuyMoreThanAvailableForSale();
        }

        // Validate that the buyer provided enough funds to make the purchase.
        uint256 buyPrice = sellOrder.unitPrice.mul(noOfTokensToBuy);
        if (msg.value < buyPrice) {
            revert SteadyMarketplace__LessETHProvidedForThePurchase();
        }

        if (
            keccak256(abi.encodePacked(nftType)) ==
            keccak256(abi.encodePacked("erc721"))
        ) {
            // Get the ERC721 contract
            IERC721 tokenContract = IERC721(contractAddress);

            // Require that the caller has approved the contract for token transfer
            if (!tokenContract.isApprovedForAll(tokenOwner, address(this))) {
                revert SteadyMarketplace__SellerHasRemovedContractsApprovalForTokenTransfer();
            }

            // Transfer ownership of the NFT from the token owner to the buyer.
            tokenContract.safeTransferFrom(tokenOwner, _msgSender(), nftId);
        } else if (
            keccak256(abi.encodePacked(nftType)) ==
            keccak256(abi.encodePacked("erc1155"))
        ) {
            // Get the IERC1155 contract
            IERC1155 tokenContract = IERC1155(contractAddress);

            // Require that the caller has approved the contract for token transfer
            require(
                tokenContract.isApprovedForAll(tokenOwner, address(this)),
                "Seller has removed contracts approval for token transfer."
            );

            // Transfer the specified number of tokens from the token owner to the buyer.
            tokenContract.safeTransferFrom(
                tokenOwner,
                _msgSender(),
                nftId,
                noOfTokensToBuy,
                ""
            );
        } else {
            // Revert if the NFT type is unsupported.
            revert("Unsupported token type.");
        }

        // Send the specified value of Ether from the buyer to the token owner
        bool sent = tokenOwner.send(msg.value);
        if (!sent) {
            revert SteadyMarketplace__FailedToSendEtherToTheTokenOwner();
        }

        /**
         * Check if the quantity of tokens being sold in the sell order is equal to the number of tokens the buyer wants to purchase.
         * If true, it removes the sell order from the list of NFT orders.
         * Otherwise, update the sell order by subtracting the number of tokens bought from the total quantity being sold.
         */
        if (sellOrder.quantity == noOfTokensToBuy) {
            nftOrders.remove(sellOrder);
        } else {
            sellOrder.quantity -= noOfTokensToBuy;
        }

        // Emit TokensSold event on successful purchase
        emit TokensSold(
            tokenOwner,
            _msgSender(),
            nftId,
            contractAddress,
            noOfTokensToBuy,
            msg.value
        );
    }

    /**
     * getOrders: This function retrieves the sell orders for the given token
     * @param nftId unique identifier of the token
     * @param contractAddress address of the contract that holds the token
     * @return An array of sell orders for the given token
     */
    function getOrders(
        uint256 nftId,
        address contractAddress
    ) external view returns (OrderSet.SellOrder[] memory) {
        bytes32 orderId = _getOrdersMapId(nftId, contractAddress);
        return orders[orderId].allOrders();
    }

    /**
     * getOrderByAddress: Get the SellOrder of a token for a given owner
     * @param nftId unique identifier of the token
     * @param contractAddress address of the contract that holds the token
     * @param listedBy address of the owner
     * @return Sell order of a token for the given owner
     */
    function getOrderByAddress(
        uint256 nftId,
        address contractAddress,
        address listedBy
    ) public view returns (OrderSet.SellOrder memory) {
        // Calculate the unique identifier for the order
        bytes32 orderId = _getOrdersMapId(nftId, contractAddress);

        // Get the SellOrderSet for the NFT
        OrderSet.Set storage nftOrders = orders[orderId];

        // Check if a SellOrder exists for the given owner
        if (nftOrders.orderExistsForAddress(listedBy)) {
            // Return the SellOrder for the given owner
            return nftOrders.orderByAddress(listedBy);
        }

        // Else, return empty SellOrder
        return OrderSet.SellOrder(address(0), 0, 0, OrderSet.Category(0), 0);
    }

    /**
     * getOrdersByCategory: This function retrieves the sell orders for the given token and category
     * @param nftId unique identifier of the token
     * @param contractAddress address of the contract that holds the token
     * @param category category of the token
     * @return An array of sell orders for the given token and category
     */
    function getOrdersByCategory(
        uint256 nftId,
        address contractAddress,
        OrderSet.Category category
    ) external view returns (OrderSet.SellOrder[] memory) {
        bytes32 orderId = _getOrdersMapId(nftId, contractAddress);
        return orders[orderId].allOrdersByCategory(category);
    }

    /**
     * getOrdersByCategoryAndAddress: This function retrieves the sell orders for the given token, category and owner
     * @param nftId unique identifier of the token
     * @param contractAddress address of the contract that holds the token
     * @param category category of the token
     * @param listedBy address of the owner
     * @return An array of sell orders for the given token, category and owner
     */
    function getOrdersByCategoryAndAddress(
        uint256 nftId,
        address contractAddress,
        OrderSet.Category category,
        address listedBy
    ) external view returns (OrderSet.SellOrder[] memory) {
        bytes32 orderId = _getOrdersMapId(nftId, contractAddress);
        return orders[orderId].ordersByAddressAndCategory(listedBy, category);
    }

    /**
     * vendorWithdrawal function allows the vendor to withdraw their funds from their gains in the their associated collections
     * @param collectionAddress address of the collection that holds the token
     * @param amount amount to be withdrawn
     */
    function vendorWithdrawal(
        address collectionAddress,
        uint256 amount
    )
        external
        onlyVendor
        validCollection(collectionAddress)
        sufficientVendorBalance(collectionAddress, amount)
    {
        vendorCollections[collectionAddress].collectionTotalSales -= amount;
        (bool vs, ) = _msgSender().call{value: amount}("");
        if (!vs) {
            revert SteadyMarketplace__FailedToSendEtherToTheVendor();
        }
    }

    /**
     * ownerWithdrawal function allows the owner to withdraw the funds from the contract
     */
    function ownerWithdrawal()
        external
        onlyOwner
        sufficientOwnerBalance(address(this).balance)
    {
        (bool os, ) = owner().call{value: address(this).balance}("");
        if (!os) {
            revert SteadyMarketplace__FailedToSendEtherToTheOwner();
        }
    }

    // _getOrdersMapId function generates the unique identifier for a given NFT id and contract address
    // The identifier is used as the key to store the corresponding SellOrderSet in the `orders` mapping
    // This helps to retrieve and manage the sell orders for a specific NFT efficiently.
    function _getOrdersMapId(
        uint256 nftId,
        address contractAddress
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(contractAddress, nftId));
    }
}
