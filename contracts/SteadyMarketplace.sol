// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*
 * @title SteadyMarketplace
 * @ description A marketplace for CryptoCities "baskets" of good and services in the ecosystem.
 * @author ricogustavo
 * @team Futurify x EpicStartups
 *
 */

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SellOrderSetLib} from "./libraries/SellOrderSetLib.sol";

contract SteadyMarketplace is Context {
    // Use SafeMath library for uint256 arithmetic operations
    using SafeMath for uint256;
    // Use SellOrderSetLib for SellOrderSetLib.Set operations
    using SellOrderSetLib for SellOrderSetLib.Set;

    // Mapping to store sell orders for different NFTs
    mapping(bytes32 => SellOrderSetLib.Set) private orders;

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
        uint8 category
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
        uint8 category
    ) external {
        // Require that the unit price of each token must be greater than 0
        require(unitPrice > 0, "NFTTrade: Price must be greater than 0.");

        // Get the unique identifier for the sell order
        bytes32 orderId = _getOrdersMapId(nftId, contractAddress);

        // Get the sell order set for the given NFT
        SellOrderSetLib.Set storage nftOrders = orders[orderId];

        // Require that the token is not already listed for sale by the same owner
        require(
            !nftOrders.orderExistsForAddress(_msgSender()),
            "NFTTrade: Token is already listed for sale by the given owner"
        );

        // Check if the NFT token is an ERC721 or ERC1155 token
        if (
            keccak256(abi.encodePacked(nftType)) ==
            keccak256(abi.encodePacked("erc721"))
        ) {
            // Get the ERC721 contract
            IERC721 tokenContract = IERC721(contractAddress);

            // Require that the caller has approved the NFTTrade contract for token transfer
            require(
                tokenContract.isApprovedForAll(_msgSender(), address(this)),
                "NFTTrade: Caller has not approved NFTTrade contract for token transfer."
            );

            // Require that the caller owns the NFT token
            require(
                tokenContract.ownerOf(nftId) == _msgSender(),
                "NFTTrade: Caller does not own the token."
            );
        } else if (
            keccak256(abi.encodePacked(nftType)) ==
            keccak256(abi.encodePacked("erc1155"))
        ) {
            // Get the ERC1155 contract
            IERC1155 tokenContract = IERC1155(contractAddress);

            // Require that the caller has approved the NFTTrade contract for token transfer
            require(
                tokenContract.isApprovedForAll(_msgSender(), address(this)),
                "NFTTrade: Caller has not approved NFTTrade contract for token transfer."
            );

            // Require that the caller has sufficient balance of the NFT token
            require(
                tokenContract.balanceOf(_msgSender(), nftId) >=
                    noOfTokensForSale,
                "NFTTrade: Insufficient token balance."
            );
        } else {
            // Revert if the NFT token is not of type ERC721 or ERC1155
            revert("NFTTrade: Unsupported token type.");
        }

        // Create a new sell order using the SellOrder constructor
        SellOrderSetLib.SellOrder memory o = SellOrderSetLib.SellOrder(
            _msgSender(),
            noOfTokensForSale,
            unitPrice,
            category
        );
        nftOrders.insert(o);

        // Emit the 'ListedForSale' event to signal that a new NFT has been listed for sale
        emit ListedForSale(
            _msgSender(),
            nftId,
            contractAddress,
            noOfTokensForSale,
            unitPrice,
            category
        );
    }

    /**
     * cancelSellOrder - Cancels the sell order created by the caller for a specific NFT token.
     *
     * @param nftId ID of the NFT token to cancel the sell order for.
     * @param contractAddress Address of the NFT contract for the NFT token.
     */
    function cancelSellOrder(uint256 nftId, address contractAddress) external {
        // Get the unique identifier for the order set of the given NFT token.
        bytes32 orderId = _getOrdersMapId(nftId, contractAddress);

        // Get the sell order set of the given NFT token.
        SellOrderSetLib.Set storage nftOrders = orders[orderId];

        // Ensure that the sell order exists for the caller.
        require(
            nftOrders.orderExistsForAddress(_msgSender()),
            "NFTTrade: Given token is not listed for sale by the owner."
        );

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
        SellOrderSetLib.Set storage nftOrders = orders[orderId];

        // Check if the token owner has a sell order for the given NFT.
        require(
            nftOrders.orderExistsForAddress(tokenOwner),
            "NFTTrade: Given token is not listed for sale by the owner."
        );

        // Get the sell order for the given NFT by the token owner.
        SellOrderSetLib.SellOrder storage sellOrder = nftOrders.orderByAddress(
            tokenOwner
        );

        // Validate that the required buy quantity is available for sale
        require(
            sellOrder.quantity >= noOfTokensToBuy,
            "NFTTrade: Attempting to buy more than available for sale."
        );

        // Validate that the buyer provided enough funds to make the purchase.
        uint256 buyPrice = sellOrder.unitPrice.mul(noOfTokensToBuy);
        require(
            msg.value >= buyPrice,
            "NFTTrade: Less ETH provided for the purchase."
        );

        if (
            keccak256(abi.encodePacked(nftType)) ==
            keccak256(abi.encodePacked("erc721"))
        ) {
            // Get the ERC721 contract
            IERC721 tokenContract = IERC721(contractAddress);

            // Require that the caller has approved the NFTTrade contract for token transfer
            require(
                tokenContract.isApprovedForAll(tokenOwner, address(this)),
                "NFTTrade: Seller has removeed NFTTrade contracts approval for token transfer."
            );

            // Transfer ownership of the NFT from the token owner to the buyer.
            tokenContract.safeTransferFrom(tokenOwner, _msgSender(), nftId);
        } else if (
            keccak256(abi.encodePacked(nftType)) ==
            keccak256(abi.encodePacked("erc1155"))
        ) {
            // Get the IERC1155 contract
            IERC1155 tokenContract = IERC1155(contractAddress);

            // Require that the caller has approved the NFTTrade contract for token transfer
            require(
                tokenContract.isApprovedForAll(tokenOwner, address(this)),
                "NFTTrade: Seller has removeed NFTTrade contracts approval for token transfer."
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
            revert("NFTTrade: Unsupported token type.");
        }

        // Send the specified value of Ether from the buyer to the token owner
        bool sent = tokenOwner.send(msg.value);
        require(sent, "Failed to send Ether to the token owner.");

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

        // Emit TokensSold event on successfull purchase
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
    ) external view returns (SellOrderSetLib.SellOrder[] memory) {
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
    ) public view returns (SellOrderSetLib.SellOrder memory) {
        // Calculate the unique identifier for the order
        bytes32 orderId = _getOrdersMapId(nftId, contractAddress);

        // Get the SellOrderSet for the NFT
        SellOrderSetLib.Set storage nftOrders = orders[orderId];

        // Check if a SellOrder exists for the given owner
        if (nftOrders.orderExistsForAddress(listedBy)) {
            // Return the SellOrder for the given owner
            return nftOrders.orderByAddress(listedBy);
        }

        // Else, return empty SellOrder
        return SellOrderSetLib.SellOrder(address(0), 0, 0, 0);
    }

    /**
     * getFloorPrice function returns the total sales on all categories
     * @param nftId unique identifier of the token
     * @param contractAddress address of the contract that holds the token
     * @return total sales on all categories
     */
    function getFloorPrice(
        uint256 nftId,
        address contractAddress
    ) external view returns (uint256) {
        bytes32 orderId = _getOrdersMapId(nftId, contractAddress);
        SellOrderSetLib.Set storage nftOrders = orders[orderId];
        return nftOrders.totalSales();
    }

    /**
     * getTotalSalesBasedOnCategory function returns the total sales on a given category
     * @param nftId unique identifier of the token
     * @param contractAddress address of the contract that holds the token
     * @param category category of the token
     * @return total sales on a given category
     */
    function getTotalSalesBasedOnCategory(
        uint256 nftId,
        address contractAddress,
        uint8 category
    ) external view returns (uint256) {
        bytes32 orderId = _getOrdersMapId(nftId, contractAddress);
        SellOrderSetLib.Set storage nftOrders = orders[orderId];
        return nftOrders.totalSalesByCategory(category);
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
