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

    // charge a fee of 100 Steady Coin to become a vendor
    uint256 public constant VENDOR_FEE = 100 ether;

    // Mapping to store sell orders for different orders
    mapping(uint256 => OrderSet.Set) private orders;

    // Vendor data structure to store vendor details
    struct Vendor {
        address vendorAddress;
        string vendorName;
        string vendorDescription;
        VendorShop[] VendorShops;
        uint256 dateCreated;
        uint256 dateUpdated;
    }
    // VendorShop data structure to store vendor shop details
    struct VendorShop {
        uint256 collectionId;
        address collectionAddress;
        OrderSet.Category category;
        string collectionName;
        string collectionDescription;
        uint256 collectionTotalSales;
        uint256 collectionTotalSalesByCategory;
        uint256 dateCreated;
        uint256 dateUpdated;
    }

    // Mapping to store vendor details
    mapping(address => VendorShop) public VendorShops;

    // Mapping to store vendor details
    mapping(address => Vendor) public vendors;

    // Event to indicate a token is listed for sale
    event ListedForSale(
        // Account address of the token owner
        address account,
        // market order id
        uint256 orderId,
        // Number of tokens for sale
        uint256 noOfTokensForSale,
        // Unit price of each token
        uint256 unitPrice,
        // Category of the item
        OrderSet.Category category,
        // Date when the item was created
        uint256 date
    );

    // Event to indicate a token is unlisted from sale
    event UnlistedFromSale(
        // Account address of the token owner
        address account,
        // market order id
        uint256 orderId
    );

    // Event to indicate a token is sold
    event TokensSold(
        // Account address of the token seller
        address from,
        // Account address of the token buyer
        address to,
        // market order id
        uint256 orderId,
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
    event VendorShopCreated(
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
    event VendorShopUpdated(
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
        if (vendors[_msgSender()].VendorShops.length == 0) {
            revert SteadyMarketplace__VendorHasNotCreatedCollection();
        }
        _;
    }

    // modifier to check if the collection is valid
    modifier validCollection(address collectionAddress) {
        if (
            VendorShops[collectionAddress].collectionAddress !=
            collectionAddress
        ) {
            revert SteadyMarketplace__CollectionDoesNotExist();
        }
        _;
    }

    // modifier to check if vendorShop name is already exists
    modifier validVendorShopName(string memory name) {
        for (uint256 i = 0; i < vendors[_msgSender()].VendorShops.length; i++) {
            if (
                keccak256(
                    bytes(vendors[_msgSender()].VendorShops[i].collectionName)
                ) == keccak256(bytes(name))
            ) {
                revert SteadyMarketplace__CollectionDoesNotExist();
            }
        }
        _;
    }

    // modifier to check if the vendor has sufficient balance
    modifier sufficientVendorBalance(
        address collectionAddress,
        uint256 amount
    ) {
        if (VendorShops[collectionAddress].collectionTotalSales < amount) {
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
            new VendorShop[](0),
            newDate,
            newDate
        );

        // Add the vendor to the vendors mapping
        vendors[_msgSender()] = v;

        // Emit the VendorCreated event
        emit VendorCreated(_msgSender(), name, description, newDate, newDate);
    }

    /**
     * registerVendorShop - Registers a new vendor collection
     * @param name - Name of the vendor
     * @param description - Description of the vendor
     * @param category - Category of the vendor
     */
    function registerVendorShop(
        string memory name,
        string memory description,
        OrderSet.Category category
    ) external payable onlyVendor validVendorShopName(name) {
        uint256 newDate = block.timestamp;

        // create random collection address for vendor
        address collectionAddress = address(
            uint160(uint256(keccak256(abi.encodePacked(_msgSender()))))
        );

        // Create a new vendor collection with push
        uint256 collectionId = vendors[_msgSender()].VendorShops.length;

        VendorShop memory vc = VendorShop(
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
        VendorShops[collectionAddress] = vc;

        // Add the vendor collection to the vendor's VendorShops array
        vendors[_msgSender()].VendorShops.push(vc);

        // Emit the VendorShopCreated event
        emit VendorShopCreated(
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
    ) external payable onlyVendor validVendorShopName(name) {
        // check if name is already exists

        uint256 newDate = block.timestamp;
        vendors[_msgSender()].vendorName = name;
        vendors[_msgSender()].vendorDescription = description;
        vendors[_msgSender()].dateUpdated = newDate;

        emit VendorUpdated(_msgSender(), name, description, newDate);
    }

    /**
     * updateVendorShop - Updates an existing vendor collection
     * @param collectionAddress - Address of the vendor collection
     * @param name - Name of the vendor collection
     * @param description - Description of the vendor collection
     */

    function updateVendorShop(
        address collectionAddress,
        string memory name,
        string memory description
    ) external payable onlyVendor validCollection(collectionAddress) {
        uint256 newDate = block.timestamp;
        VendorShops[collectionAddress].collectionName = name;
        VendorShops[collectionAddress].collectionDescription = description;
        VendorShops[collectionAddress].dateUpdated = newDate;

        emit VendorShopUpdated(
            _msgSender(),
            VendorShops[collectionAddress].collectionId,
            collectionAddress,
            name,
            description,
            newDate
        );
    }

    /**
     * createSellOrder - Creates a sell order for the item specified by `orderId`
     *
     * @param orderId        - The ID of the item being sold.
     * @param unitPrice      - The price of a single item in wei.
     * @param noOfTokensForSale - The number of itemss being sold.
     * @param category       - The category of the item.
     */

    function createSellOrder(
        uint256 orderId,
        uint256 unitPrice,
        uint256 noOfTokensForSale,
        OrderSet.Category category
    ) external onlyVendor hasCreatedCollection {
        if (unitPrice <= 0) {
            revert SteadyMarketplace__InsufficientBalance();
        }

        // Get the sell order set for the given item
        OrderSet.Set storage marketOrder = orders[orderId];

        // Require that the token is not already listed for sale by the same owner
        if (marketOrder.orderExistsForAddress(_msgSender())) {
            revert SteadyMarketplace__InsufficientBalance();
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
        marketOrder.insert(o);

        // Emit the 'ListedForSale' event to signal that a new item has been listed for sale
        emit ListedForSale(
            _msgSender(),
            orderId,
            noOfTokensForSale,
            unitPrice,
            category,
            newDate
        );
    }

    /**
     * cancelSellOrder - Cancels the sell order created by the caller for a specific item token.
     *
     * @param orderId - The ID of the item to be unlisted.
     */
    function cancelSellOrder(
        uint256 orderId
    ) external onlyVendor hasCreatedCollection {
        // Get the sell order set of the given item token.
        OrderSet.Set storage itemOrders = orders[orderId];

        // Ensure that the sell order exists for the caller.
        if (!itemOrders.orderExistsForAddress(_msgSender())) {
            revert SteadyMarketplace__TokenIsNotListedForSaleByTheOwner();
        }

        // Remove the sell order from the set.
        itemOrders.remove(itemOrders.orderByAddress(_msgSender()));

        // Emit an event indicating that the sell order has been unlisted.
        emit UnlistedFromSale(_msgSender(), orderId);
    }

    /**
     * createBuyOrder - Create a buy order for an item token.
     *
     * @param orderId - The ID of the item being sold.
     * @param noOfTokensToBuy - number of tokens the buyer wants to purchase.
     * @param tokenOwner - address of the seller who is selling the token.
     */

    function createBuyOrder(
        uint256 orderId,
        uint256 noOfTokensToBuy,
        address payable tokenOwner
    ) external payable {
        // Get the unique identifier for the order set of the given item token.

        // Get the sell order set of the given item token.
        OrderSet.Set storage itemOrders = orders[orderId];

        // Check if the token owner has a sell order for the given item.
        if (!itemOrders.orderExistsForAddress(tokenOwner)) {
            revert SteadyMarketplace__TokenIsNotListedForSaleByTheOwner();
        }

        // Get the sell order for the given item by the token owner.
        OrderSet.SellOrder storage sellOrder = itemOrders.orderByAddress(
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

        // Send the specified value of Ether from the buyer to the token owner
        bool sent = tokenOwner.send(msg.value);
        if (!sent) {
            revert SteadyMarketplace__FailedToSendEtherToTheTokenOwner();
        }

        /**
         * Check if the quantity of tokens being sold in the sell order is equal to the number of tokens the buyer wants to purchase.
         * If true, it removes the sell order from the list of item orders.
         * Otherwise, update the sell order by subtracting the number of tokens bought from the total quantity being sold.
         */
        if (sellOrder.quantity == noOfTokensToBuy) {
            itemOrders.remove(sellOrder);
        } else {
            sellOrder.quantity -= noOfTokensToBuy;
        }

        // Emit TokensSold event on successful purchase
        emit TokensSold(
            tokenOwner,
            _msgSender(),
            orderId,
            noOfTokensToBuy,
            msg.value
        );
    }

    /**
     * getOrders: This function retrieves the sell orders for the given token
     * @param orderId  - The ID of of the item
     * @return An array of sell orders for the given token
     */
    function getOrders(
        uint256 orderId
    ) external view returns (OrderSet.SellOrder[] memory) {
        return orders[orderId].allOrders();
    }

    /**
     * getOrderByAddress: Get the SellOrder of a token for a given owner
     * @param orderId the ID of the item
     * @param listedBy address of the owner
     * @return Sell order of a token for the given owner
     */
    function getOrderByAddress(
        uint256 orderId,
        address listedBy
    ) public view returns (OrderSet.SellOrder memory) {
        // Get the SellOrderSet for the item
        OrderSet.Set storage itemOrders = orders[orderId];

        // Check if a SellOrder not exists for the given owner
        if (!itemOrders.orderExistsForAddress(listedBy)) {
            // If true, return an empty SellOrder
            return
                OrderSet.SellOrder(address(0), 0, 0, OrderSet.Category(0), 0);
        }
        // Else  Return the SellOrder for the given owner
        return itemOrders.orderByAddress(listedBy);
    }

    /**
     * getOrdersByCategory: This function retrieves the sell orders for the given token and category
     * @param orderId the ID of the item
     * @param category category of the token
     * @return An array of sell orders for the given token and category
     */
    function getOrdersByCategory(
        uint256 orderId,
        OrderSet.Category category
    ) external view returns (OrderSet.SellOrder[] memory) {
        return orders[orderId].allOrdersByCategory(category);
    }

    /**
     * getOrdersByCategoryAndAddress: This function retrieves the sell orders for the given token, category and owner
     * @param orderId the ID of the item
     * @param category category of the token
     * @param listedBy address of the owner
     * @return An array of sell orders for the given token, category and owner
     */
    function getOrdersByCategoryAndAddress(
        uint256 orderId,
        OrderSet.Category category,
        address listedBy
    ) external view returns (OrderSet.SellOrder[] memory) {
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
        VendorShops[collectionAddress].collectionTotalSales -= amount;
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
}
