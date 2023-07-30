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
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SellOrderSetLib} from "./libraries/SellOrderSetLib.sol";

contract SteadyMarketplace is Context {
    using SafeMath for uint256;
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
        uint256 unitPrice
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
     * @param unitPrice      - The price of a single NFT in wei.
     * @param noOfTokensForSale - The number of NFTs being sold.
     */

    function createSellOrder(
        uint256 nftId,
        address contractAddress,
        uint256 unitPrice,
        uint256 noOfTokensForSale
    ) external {
        // Require that the unit price of each token must be greater than 0
        require(
            unitPrice > 0,
            "SteadyMarketplace: Price must be greater than 0."
        );

        // Get the unique identifier for the sell order
        bytes32 orderId = _getOrdersMapId(nftId, contractAddress);

        // Get the sell order set for the given NFT
        SellOrderSetLib.Set storage nftOrders = orders[orderId];

        // Require that the token is not already listed for sale by the same owner
        require(
            !nftOrders.orderExistsForAddress(_msgSender()),
            "SteadyMarketplace: Token is already listed for sale by the given owner"
        );

        // Get the ERC1155 contract
        IERC1155 tokenContract = IERC1155(contractAddress);

        // Require that the caller has approved the SteadyMarketplace contract for token transfer
        require(
            tokenContract.isApprovedForAll(_msgSender(), address(this)),
            "SteadyMarketplace: Caller has not approved SteadyMarketplace contract for token transfer."
        );

        // Require that the caller has sufficient balance of the NFT token
        require(
            tokenContract.balanceOf(_msgSender(), nftId) >= noOfTokensForSale,
            "SteadyMarketplace: Insufficient token balance."
        );
        // Create a new sell order using the SellOrder constructor
        SellOrderSetLib.SellOrder memory o = SellOrderSetLib.SellOrder(
            _msgSender(),
            noOfTokensForSale,
            unitPrice
        );
        nftOrders.insert(o);

        // Emit the 'ListedForSale' event to signal that a new NFT has been listed for sale
        emit ListedForSale(
            _msgSender(),
            nftId,
            contractAddress,
            noOfTokensForSale,
            unitPrice
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
            "SteadyMarketplace: Given token is not listed for sale by the owner."
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
     * @param noOfTokensToBuy - number of tokens the buyer wants to purchase.
     * @param tokenOwner - address of the seller who is selling the token.
     */

    function createBuyOrder(
        uint256 nftId,
        address contractAddress,
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
            "SteadyMarketplace: Given token is not listed for sale by the owner."
        );

        // Get the sell order for the given NFT by the token owner.
        SellOrderSetLib.SellOrder storage sellOrder = nftOrders.orderByAddress(
            tokenOwner
        );

        // Validate that the required buy quantity is available for sale
        require(
            sellOrder.quantity >= noOfTokensToBuy,
            "SteadyMarketplace: Attempting to buy more than available for sale."
        );

        // Validate that the buyer provided enough funds to make the purchase.
        uint256 buyPrice = sellOrder.unitPrice.mul(noOfTokensToBuy);
        require(
            msg.value >= buyPrice,
            "SteadyMarketplace: Less ETH provided for the purchase."
        );

        // Get the IERC1155 contract
        IERC1155 tokenContract = IERC1155(contractAddress);

        // Require that the caller has approved the SteadyMarketplace contract for token transfer
        require(
            tokenContract.isApprovedForAll(tokenOwner, address(this)),
            "SteadyMarketplace: Seller has removeed SteadyMarketplace contracts approval for token transfer."
        );

        // Transfer the specified number of tokens from the token owner to the buyer.
        tokenContract.safeTransferFrom(
            tokenOwner,
            _msgSender(),
            nftId,
            noOfTokensToBuy,
            ""
        );

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
        return SellOrderSetLib.SellOrder(address(0), 0, 0);
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

    /**
     * getFloorPrice: Get the floor price of a token
     * @param contractAddress address of the contract that holds the token
     * @return floor price of the token
     */
    function getFloorPrice(
        address contractAddress
    ) external view returns (uint256) {}

    /**
     * getFloorPriceByCategory: Get the floor price of a token by category
     * @param contractAddress address of the contract that holds the token
     * @param category category of the token
     * @return floor price of the token
     */
    function getFloorPriceByCategory(
        address contractAddress,
        string memory category
    ) external view returns (uint256) {}
}
