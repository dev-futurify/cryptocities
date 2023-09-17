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

interface ISteadyFormula {
    function _totalSalesByVendor() external view returns (uint256);
}

contract SteadyMarketplace is Context, Ownable {
    error SteadyMarketplace__OnlyVendor();
    error SteadyMarketplace__VendorNameAlreadyExist();
    error SteadyMarketplace__VendorFeeNotPaid();
    error SteadyMarketplace__VendorHasNotCreatedStore();
    error SteadyMarketplace__StoreNameAlreadyExist();
    error SteadyMarketplace__StoreDoesNotExist();
    error SteadyMarketplace__InsufficientBalance();
    error SteadyMarketplace__CallerHasNotApprovedContractForItemTransfer();
    error SteadyMarketplace__CallerDoesNotOwnItem();
    error SteadyMarketplace__ItemIsNotListedForSaleByTheOwner();
    error SteadyMarketplace__AttemptingToBuyMoreThanAvailableForSale();
    error SteadyMarketplace__LessETHProvidedForThePurchase();
    error SteadyMarketplace__SellerHasRemovedContractsApprovalForItemTransfer();
    error SteadyMarketplace__FailedToSendEtherToTheItemOwner();
    error SteadyMarketplace__FailedToSendEtherToTheVendor();
    error SteadyMarketplace__FailedToSendEtherToTheOwner();

    // Use SafeMath library for uint256 arithmetic operations
    using SafeMath for uint256;

    // Use OrderSet for OrderSet.Set operations
    using OrderSet for OrderSet.Set;

    // charge a fee of 100 Steady Coin to become a vendor
    uint256 public constant VENDOR_FEE = 100 ether;

    // SteadyFormula contract address
    ISteadyFormula private i_formula;

    // Mapping to store sell orders for different orders
    mapping(uint256 => OrderSet.Set) private orders;

    // counter to keep track of the number of vendors
    uint256 public vendorIdCounter = 1;

    // counter to keep track of the number of stores and it will be associated with the vendor
    uint256 public storeCounter;

    // Vendor data structure to store vendor details
    struct Vendor {
        uint256 vendorId;
        address vendorAddress;
        string vendorName;
        string vendorDescription;
        string vendorBusinessRegistrationNumber;
        uint256 dateCreated;
        uint256 dateUpdated;
    }
    // VendorStore data structure to store vendor store details

    struct VendorStore {
        uint256 storeId;
        address vendorAddress;
        address storeAddress;
        string storeName;
        string storeDescription;
        OrderSet.Category category;
        uint256 dateCreated;
        uint256 dateUpdated;
    }

    // Mapping to store vendor details
    mapping(address => Vendor) public allVendors;

    // Mapping to store vendor stores details
    mapping(address => VendorStore) public allVendorStores;

    // Event when new vendor is created
    // Account address of the vendor
    event VendorCreated(
        address vendorAddress,
        // Id of the vendor
        uint256 vendorId,
        // Name of the vendor
        string vendorName,
        // Description of the vendor
        string vendorDescription,
        // Date when the vendor was created
        // Business registration number of the vendor
        string vendorBusinessRegistrationNumber,
        uint256 dateCreated,
        // Date when the vendor was updated
        uint256 dateUpdated
    );

    // Event when vendor is updated
    // Account address of the vendor
    event VendorUpdated(
        address vendorAddress,
        // Id of the vendor
        uint256 vendorId,
        // Name of the vendor
        string vendorName,
        // Description of the vendor
        string vendorDescription,
        // Business registration number of the vendor
        string vendorBusinessRegistrationNumber,
        // Date when the vendor was updated
        uint256 dateUpdated
    );

    // Event when new vendor store is created
    // store id of the vendor
    event VendorStoreCreated(
        uint256 storeId,
        // Account address of the vendor
        address vendorAddress,
        // store address of the vendor
        address storeAddress,
        // Name of the vendor
        string vendorName,
        // Description of the vendor
        string vendorDescription,
        // Category of the item
        OrderSet.Category category,
        // Date when the vendor was created
        uint256 dateCreated,
        // Date when the vendor was updated
        uint256 dateUpdated
    );

    // Event when vendor store is updated
    // Account address of the vendor
    event VendorStoreUpdated(
        address vendorAddress,
        // store id of the vendor
        uint256 storeId,
        // store address of the vendor
        address storeAddress,
        // Name of the vendor
        string vendorName,
        // Description of the vendor
        string vendorDescription,
        // Date when the vendor was updated
        uint256 dateUpdated
    );

    // Event to indicate a item is listed for sale
    // Account address of the item owner
    event ListedForSale(
        address account,
        // market order id
        uint256 orderId,
        // Number of items for sale
        uint256 noOfItemsForSale,
        // Unit price of each item
        uint256 unitPrice,
        // Category of the item
        OrderSet.Category category,
        // Date when the item was created
        uint256 date
    );

    // Event to indicate a item is unlisted from sale
    // Account address of the item owner
    event UnlistedFromSale(
        address account,
        // market order id
        uint256 orderId
    );

    // Event to indicate a item is sold
    // Account address of the item seller
    event ItemSold(
        address from,
        // Account address of the item buyer
        address to,
        // market order id
        uint256 orderId,
        // Number of items sold
        uint256 itemCount,
        // Purchase amount
        uint256 puchaseAmount
    );

    // modifier to check if the caller is a vendor
    modifier onlyVendor() {
        if (allVendors[_msgSender()].vendorAddress != _msgSender()) {
            revert SteadyMarketplace__OnlyVendor();
        }
        _;
    }

    // modifier to check if the user paid the vendor fee
    modifier paidVendorFee() {
        if (msg.value < VENDOR_FEE) {
            revert SteadyMarketplace__VendorFeeNotPaid();
        }
        _;
    }

    // modifier to check if the vendor name is already exists
    modifier validVendorName(string memory name) {
        for (uint256 i = 0; i < vendorIdCounter; i++) {
            if (keccak256(bytes(allVendors[_msgSender()].vendorName)) == keccak256(bytes(name))) {
                revert SteadyMarketplace__VendorNameAlreadyExist();
            }
        }
        _;
    }

    // modifier to check if the vendor has created a store
    modifier hasCreatedStore() {
        if (allVendorStores[_msgSender()].storeAddress == address(0)) {
            revert SteadyMarketplace__VendorHasNotCreatedStore();
        }
        _;
    }

    // modifier to check if the store is valid
    modifier validStore(address storeAddress) {
        if (allVendorStores[storeAddress].storeAddress != storeAddress) {
            revert SteadyMarketplace__StoreDoesNotExist();
        }
        _;
    }

    // modifier to check if vendorStore name is already exists
    modifier validVendorStoreName(string memory name) {
        for (uint256 i = 0; i < allVendorStores[_msgSender()].storeId; i++) {
            if (keccak256(bytes(allVendorStores[_msgSender()].storeName)) == keccak256(bytes(name))) {
                revert SteadyMarketplace__StoreNameAlreadyExist();
            }
        }
        _;
    }

    // modifier to check if the vendor has sufficient balance
    modifier sufficientVendorBalance(address storeAddress, uint256 amount) {
        if (i_formula._totalSalesByVendor() < amount) {
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

    constructor(address formulaAddress) {
        i_formula = ISteadyFormula(formulaAddress);
    }

    /**
     * registerVendor - Registers a new vendor
     * @param vendorName - Name of the vendor
     * @param vendorDescription - Description of the vendor
     * @param vendorBusinessRegistrationNumber - Business registration number of the vendor
     */
    function registerVendor(
        string memory vendorName,
        string memory vendorDescription,
        string memory vendorBusinessRegistrationNumber
    ) external payable paidVendorFee {
        uint256 newDate = block.timestamp;
        // Create a new vendor with push
        Vendor memory v = Vendor(
            vendorIdCounter,
            _msgSender(),
            vendorName,
            vendorDescription,
            vendorBusinessRegistrationNumber,
            newDate,
            newDate
        );

        // Add the vendor to the vendors mapping
        allVendors[_msgSender()] = v;

        // Emit the VendorCreated event
        emit VendorCreated(
            _msgSender(),
            vendorIdCounter,
            vendorName,
            vendorDescription,
            vendorBusinessRegistrationNumber,
            newDate,
            newDate
        );

        // Increment the vendor counter
        vendorIdCounter++;
    }

    /**
     * updateVendor - Updates an existing vendor
     * @param vendorAddress - Address of the vendor
     * @param vendorId - Id of the vendor
     * @param vendorName - Name of the vendor
     * @param vendorDescription - Description of the vendor
     * @param vendorBusinessRegistrationNumber - Business registration number of the vendor
     */
    function updateVendor(
        address vendorAddress,
        uint256 vendorId,
        string memory vendorName,
        string memory vendorDescription,
        string memory vendorBusinessRegistrationNumber
    ) external onlyVendor validVendorName(vendorName) {
        uint256 newDate = block.timestamp;
        allVendors[vendorAddress].vendorName = vendorName;
        allVendors[vendorAddress].vendorDescription = vendorDescription;
        allVendors[vendorAddress].vendorBusinessRegistrationNumber = vendorBusinessRegistrationNumber;
        allVendors[vendorAddress].dateUpdated = newDate;

        emit VendorUpdated(
            vendorAddress, vendorId, vendorName, vendorDescription, vendorBusinessRegistrationNumber, newDate
        );
    }

    /**
     * getAllVendors - Returns all the vendors
     *
     * @return An array of vendors
     */
    function getAllVendors() external view returns (Vendor[] memory) {
        Vendor[] memory vendors = new Vendor[](vendorIdCounter);
        for (uint256 i = 0; i < vendorIdCounter; i++) {
            vendors[i] = allVendors[_msgSender()];
        }
        return vendors;
    }

    /**
     * getVendorByAddress - Returns the vendor details for the given vendor address
     * @param vendorAddress - Address of the vendor
     * @return Vendor details
     */
    function getVendorByAddress(address vendorAddress) external view returns (Vendor memory) {
        return allVendors[vendorAddress];
    }

    /**
     * getVendorById - Returns the vendor details for the given vendor id
     * @param vendorId - Id of the vendor
     * @return Vendor details
     */
    function getVendorById(uint256 vendorId) external view returns (Vendor memory) {
        for (uint256 i = 0; i < vendorIdCounter; i++) {
            if (allVendors[_msgSender()].vendorId == vendorId) {
                return allVendors[_msgSender()];
            }
        }
        return Vendor(0, address(0), "", "", "", block.timestamp, block.timestamp);
    }

    /**
     * getVendorByName - Returns the vendor details for the given vendor name
     * @param vendorName - Name of the vendor
     * @return Vendor details
     */
    function getVendorByName(string memory vendorName) external view returns (Vendor memory) {
        for (uint256 i = 0; i < vendorIdCounter; i++) {
            if (keccak256(bytes(allVendors[_msgSender()].vendorName)) == keccak256(bytes(vendorName))) {
                return allVendors[_msgSender()];
            }
        }
        return Vendor(0, address(0), "", "", "", block.timestamp, block.timestamp);
    }

    /**
     * registerVendorStore - Registers a new vendor store
     * @param storeName - Name of the vendor
     * @param storeDescription - Description of the vendor
     * @param storeCategory - Category of the vendor
     */
    function registerVendorStore(
        string memory storeName,
        string memory storeDescription,
        OrderSet.Category storeCategory
    ) external onlyVendor validVendorStoreName(storeName) {
        uint256 newDate = block.timestamp;

        // create random store address for vendor
        address storeAddress = address(uint160(uint256(keccak256(abi.encodePacked(_msgSender())))));

        // Create a new vendor store with push
        VendorStore memory vc = VendorStore(
            storeCounter, _msgSender(), storeAddress, storeName, storeDescription, storeCategory, newDate, newDate
        );

        // Add the vendor store to the vendor stores mapping
        allVendorStores[storeAddress] = vc;

        // Add the vendor store to the vendor's VendorStores array
        // allVendors[_msgSender()].VendorStores.push(vc);

        // Emit the VendorStoreCreated event
        emit VendorStoreCreated(
            storeCounter, _msgSender(), storeAddress, storeName, storeDescription, storeCategory, newDate, newDate
        );
    }

    /**
     * updateVendorStore - Updates an existing vendor store
     * @param storeAddress - Address of the vendor store
     * @param storeName - Name of the vendor store
     * @param storeDescription - Description of the vendor store
     */

    function updateVendorStore(address storeAddress, string memory storeName, string memory storeDescription)
        external
        onlyVendor
        validStore(storeAddress)
    {
        uint256 newDate = block.timestamp;
        allVendorStores[storeAddress].storeName = storeName;
        allVendorStores[storeAddress].storeDescription = storeDescription;
        allVendorStores[storeAddress].dateUpdated = newDate;

        emit VendorStoreUpdated(
            _msgSender(), allVendorStores[storeAddress].storeId, storeAddress, storeName, storeDescription, newDate
        );
    }

    /**
     * getAllVendorStore - Returns all the vendor stores
     *
     * @return An array of vendor stores
     */
    function getAllVendorStore() external view returns (VendorStore[] memory) {
        VendorStore[] memory vendorStores = new VendorStore[](storeCounter);
        for (uint256 i = 0; i < storeCounter; i++) {
            vendorStores[i] = allVendorStores[_msgSender()];
        }
        return vendorStores;
    }

    /**
     * getVendorStoreByAddress - Returns the vendor store details for the given vendor store address
     * @param storeAddress - Address of the vendor store
     * @return Vendor store details
     */
    function getVendorStoreByAddress(address storeAddress) external view returns (VendorStore memory) {
        return allVendorStores[storeAddress];
    }

    /**
     * getVendorStoreById - Returns the vendor store details for the given vendor store id
     * @param storeId - Id of the vendor store
     * @return Vendor store details
     */
    function getVendorStoreById(uint256 storeId) external view returns (VendorStore memory) {
        for (uint256 i = 0; i < storeCounter; i++) {
            if (allVendorStores[_msgSender()].storeId == storeId) {
                return allVendorStores[_msgSender()];
            }
        }
        return VendorStore(0, address(0), address(0), "", "", OrderSet.Category(0), block.timestamp, block.timestamp);
    }

    /**
     * getVendorStoreByName - Returns the vendor store details for the given vendor store name
     * @param name - Name of the vendor store
     * @return Vendor store details
     */
    function getVendorStoreByName(string memory name) external view returns (VendorStore memory) {
        for (uint256 i = 0; i < storeCounter; i++) {
            if (keccak256(bytes(allVendorStores[_msgSender()].storeName)) == keccak256(bytes(name))) {
                return allVendorStores[_msgSender()];
            }
        }
        return VendorStore(0, address(0), address(0), "", "", OrderSet.Category(0), block.timestamp, block.timestamp);
    }

    /*
     * getStoreByVendorAddress - Returns the vendor store details for the given vendor address
     * @param vendorAddress - Address of the vendor
     * @return Vendor store details
     */
    function getStoreByVendorAddress(address vendorAddress) external view returns (VendorStore memory) {
        return allVendorStores[vendorAddress];
    }

    /**
     * createSellOrder - Creates a sell order for the item specified by `orderId`
     *
     * @param orderId        - The ID of the item being sold.
     * @param unitPrice      - The price of a single item in wei.
     * @param noOfItemsForSale - The number of itemss being sold.
     * @param category       - The category of the item.
     */

    function createSellOrder(uint256 orderId, uint256 unitPrice, uint256 noOfItemsForSale, OrderSet.Category category)
        external
        onlyVendor
        hasCreatedStore
    {
        if (unitPrice <= 0) {
            revert SteadyMarketplace__InsufficientBalance();
        }

        // Get the sell order set for the given item
        OrderSet.Set storage marketOrder = orders[orderId];

        // Require that the item is not already listed for sale by the same owner
        if (marketOrder.orderExistsForAddress(_msgSender())) {
            revert SteadyMarketplace__InsufficientBalance();
        }

        uint256 newDate = block.timestamp;

        // Create a new sell order using the SellOrder constructor
        OrderSet.SellOrder memory o =
            OrderSet.SellOrder(_msgSender(), noOfItemsForSale, unitPrice, OrderSet.Category(category), newDate);
        marketOrder.insert(o);

        // Emit the 'ListedForSale' event to signal that a new item has been listed for sale
        emit ListedForSale(_msgSender(), orderId, noOfItemsForSale, unitPrice, category, newDate);
    }

    /**
     * cancelSellOrder - Cancels the sell order created by the caller for a specific item.
     *
     * @param orderId - The ID of the item to be unlisted.
     */
    function cancelSellOrder(uint256 orderId) external onlyVendor hasCreatedStore {
        // Get the sell order set of the given item.
        OrderSet.Set storage itemOrders = orders[orderId];

        // Ensure that the sell order exists for the caller.
        if (!itemOrders.orderExistsForAddress(_msgSender())) {
            revert SteadyMarketplace__ItemIsNotListedForSaleByTheOwner();
        }

        // Remove the sell order from the set.
        itemOrders.remove(itemOrders.orderByAddress(_msgSender()));

        // Emit an event indicating that the sell order has been unlisted.
        emit UnlistedFromSale(_msgSender(), orderId);
    }

    /**
     * createBuyOrder - Create a buy order for an item.
     *
     * @param orderId - The ID of the item being sold.
     * @param noOfItemsToBuy - number of items the buyer wants to purchase.
     * @param itemOwner - address of the seller who is selling the item.
     */

    function createBuyOrder(uint256 orderId, uint256 noOfItemsToBuy, address payable itemOwner) external payable {
        // Get the unique identifier for the order set of the given item.

        // Get the sell order set of the given item.
        OrderSet.Set storage itemOrders = orders[orderId];

        // Check if the item owner has a sell order for the given item.
        if (!itemOrders.orderExistsForAddress(itemOwner)) {
            revert SteadyMarketplace__ItemIsNotListedForSaleByTheOwner();
        }

        // Get the sell order for the given item by the item owner.
        OrderSet.SellOrder storage sellOrder = itemOrders.orderByAddress(itemOwner);

        // Validate that the required buy quantity is available for sale
        if (sellOrder.quantity < noOfItemsToBuy) {
            revert SteadyMarketplace__AttemptingToBuyMoreThanAvailableForSale();
        }

        // Validate that the buyer provided enough funds to make the purchase.
        uint256 buyPrice = sellOrder.unitPrice.mul(noOfItemsToBuy);
        if (msg.value < buyPrice) {
            revert SteadyMarketplace__LessETHProvidedForThePurchase();
        }

        // Send the specified value of Ether from the buyer to the item owner
        bool sent = itemOwner.send(msg.value);
        if (!sent) {
            revert SteadyMarketplace__FailedToSendEtherToTheItemOwner();
        }

        /**
         * Check if the quantity of items being sold in the sell order is equal to the number of items the buyer wants to purchase.
         * If true, it removes the sell order from the list of item orders.
         * Otherwise, update the sell order by subtracting the number of items bought from the total quantity being sold.
         */
        if (sellOrder.quantity == noOfItemsToBuy) {
            itemOrders.remove(sellOrder);
        } else {
            sellOrder.quantity -= noOfItemsToBuy;
        }

        // Emit ItemSold event on successful purchase
        emit ItemSold(itemOwner, _msgSender(), orderId, noOfItemsToBuy, msg.value);
    }

    /**
     * getOrders: This function retrieves the sell orders for the given item
     * @param orderId  - The ID of of the item
     * @return An array of sell orders for the given item
     */
    function getOrders(uint256 orderId) external view returns (OrderSet.SellOrder[] memory) {
        return orders[orderId].allOrders();
    }

    /**
     * getOrderByAddress: Get the SellOrder of a item for a given owner
     * @param orderId the ID of the item
     * @param listedBy address of the owner
     * @return Sell order of a item for the given owner
     */
    function getOrderByAddress(uint256 orderId, address listedBy) public view returns (OrderSet.SellOrder memory) {
        // Get the SellOrderSet for the item
        OrderSet.Set storage itemOrders = orders[orderId];

        // Check if a SellOrder not exists for the given owner
        if (!itemOrders.orderExistsForAddress(listedBy)) {
            // If true, return an empty SellOrder
            return OrderSet.SellOrder(address(0), 0, 0, OrderSet.Category(0), 0);
        }
        // Else  Return the SellOrder for the given owner
        return itemOrders.orderByAddress(listedBy);
    }

    /**
     * getOrdersByCategory: This function retrieves the sell orders for the given item and category
     * @param orderId the ID of the item
     * @param category category of the item
     * @return An array of sell orders for the given item and category
     */
    function getOrdersByCategory(uint256 orderId, OrderSet.Category category)
        external
        view
        returns (OrderSet.SellOrder[] memory)
    {
        return orders[orderId].allOrdersByCategory(category);
    }

    /**
     * getOrdersByCategoryAndAddress: This function retrieves the sell orders for the given item, category and owner
     * @param orderId the ID of the item
     * @param category category of the item
     * @param listedBy address of the owner
     * @return An array of sell orders for the given item, category and owner
     */
    function getOrdersByCategoryAndAddress(uint256 orderId, OrderSet.Category category, address listedBy)
        external
        view
        returns (OrderSet.SellOrder[] memory)
    {
        return orders[orderId].ordersByAddressAndCategory(listedBy, category);
    }

    /**
     * vendorWithdrawal function allows the vendor to withdraw their funds from their gains in the their associated stores
     * @param storeAddress address of the store that holds the item
     * @param amount amount to be withdrawn
     */
    function vendorWithdrawal(address storeAddress, uint256 amount)
        external
        onlyVendor
        validStore(storeAddress)
        sufficientVendorBalance(storeAddress, amount)
    {
        (bool vs,) = _msgSender().call{value: amount}("");
        if (!vs) {
            revert SteadyMarketplace__FailedToSendEtherToTheVendor();
        }
    }

    /**
     * ownerWithdrawal function allows the owner to withdraw the funds from the contract
     */
    function ownerWithdrawal() external onlyOwner sufficientOwnerBalance(address(this).balance) {
        (bool os,) = owner().call{value: address(this).balance}("");
        if (!os) {
            revert SteadyMarketplace__FailedToSendEtherToTheOwner();
        }
    }

    /**
     * Change the contract address of the SteadyFormula contract
     */
    function changeFormulaAddress(address newAddress) external onlyOwner {
        i_formula = ISteadyFormula(newAddress);
    }
}
