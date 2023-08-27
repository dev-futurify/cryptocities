// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
 * @title OrderSet - Steady Marketplace extension library for managing
 * the basket of goods and services.
 * @author ricogustavo
 * @team Futurify x EpicStartups
 * @notice Reference to the Hitchens UnorderedKeySet library version 0.93
 * https://github.com/rob-Hitchens/UnorderedKeySet
 *
 */

library OrderSet {
    error OrderSetLib__SellOrderCannotBeListedByZeroAddress();
    error OrderSetLib__SellOrderCannotHaveZeroTokenCount();
    error OrderSetLib__SellOrderCannotHaveZeroTokenPrice();
    error OrderSetLib__KeyAlreadyExistsInSet();
    error OrderSetLib__CategoryMustBeBetween0And7();
    error OrderSetLib__DateSoldMustBeBlockTimestamp();
    error OrderSetLib__KeyDoesNotExistInSet();

    // Category enum representing the major groups of the CPI
    enum Category {
        FoodAndBeverages,
        Housing,
        Apparel,
        Transportation,
        EducationAndCommunication,
        OtherGoodsAndServices,
        Recreation,
        MedicalCare
    }

    modifier validCategory(Category category) {
        if (uint8(category) < 0 || uint8(category) > 7) {
            revert OrderSetLib__CategoryMustBeBetween0And7();
        }
        _;
    }

    // SellOrder structure representing a sell order, containing the address of the seller, the quantity of tokens being sold, and the unit price of the tokens.
    struct SellOrder {
        address listedBy; // Address of the seller
        uint256 quantity; // Quantity of tokens being sold
        uint256 unitPrice; // Unit price of the tokens
        Category category; // Category of the sell order
        uint256 dateSold; // Date the sell order was created
    }

    // Set structure containing a mapping of seller addresses to indices in the keyList array, and an array of SellOrders.
    struct Set {
        mapping(address => uint256) keyPointers; // Mapping of seller addresses to indices in the keyList array
        SellOrder[] keyList; // Array of SellOrders
    }

    // Function to insert a SellOrder into the Set.
    function insert(
        Set storage self,
        SellOrder memory key
    ) internal validCategory(Category(key.category)) {
        // Check if the seller address is address(0), which is not allowed.
        if (key.listedBy == address(0)) {
            revert OrderSetLib__SellOrderCannotBeListedByZeroAddress();
        }

        // Check if the quantity of tokens being sold is greater than 0.
        if (key.quantity <= 0) {
            revert OrderSetLib__SellOrderCannotHaveZeroTokenCount();
        }

        // Check if the unit price of the tokens is greater than 0.
        if (key.unitPrice <= 0) {
            revert OrderSetLib__SellOrderCannotHaveZeroTokenPrice();
        }

        // Check if the SellOrder is already in the Set.
        if (exists(self, key)) {
            revert OrderSetLib__KeyAlreadyExistsInSet();
        }

        // Check if the category is between 1 and 8.
        if (uint8(key.category) < 0 || uint8(key.category) > 7) {
            revert OrderSetLib__CategoryMustBeBetween0And7();
        }

        // Check if the dateSold is block.timestamp.
        if (key.dateSold != block.timestamp) {
            revert OrderSetLib__DateSoldMustBeBlockTimestamp();
        }

        // If all checks pass, add the SellOrder to the keyList array.
        self.keyList.push(key);
        // Update the keyPointers mapping with the index of the newly added SellOrder.
        self.keyPointers[key.listedBy] = self.keyList.length - 1;
    }

    function remove(
        Set storage self,
        SellOrder memory key
    ) internal validCategory(Category(key.category)) {
        if (!exists(self, key)) {
            revert OrderSetLib__KeyDoesNotExistInSet();
        }

        // Store the last sell order in the keyList in memory
        SellOrder memory keyToMove = self.keyList[count(self) - 1];

        // Get the row number in keyList that corresponds to the sell order being removed
        uint256 rowToReplace = self.keyPointers[key.listedBy];

        // Replace the sell order being removed with the last sell order in the keyList
        self.keyPointers[keyToMove.listedBy] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;

        // Delete the sell order being removed from the keyPointers mapping
        delete self.keyPointers[key.listedBy];

        // Pop the last sell order from the keyList
        self.keyList.pop();
    }

    /**
     * Get the number of sell orders in the set
     *
     * @param self Set The set of sell orders
     * @return uint256 The number of sell orders in the set
     */
    function count(Set storage self) internal view returns (uint256) {
        return (self.keyList.length);
    }

    /**
     * Check if a sell order already exists in the set
     *
     * @param self Set The set of sell orders
     * @param key SellOrder The sell order to check for existence
     * @return bool True if the sell order exists in the set, false otherwise
     */
    function exists(
        Set storage self,
        SellOrder memory key
    ) internal view returns (bool) {
        if (self.keyList.length == 0) return false;
        SellOrder storage o = self.keyList[self.keyPointers[key.listedBy]];
        return (o.listedBy == key.listedBy);
    }

    /**
     * Check if a sell order has been listed by a specific address
     *
     * @param self Set The set of sell orders
     * @param listedBy address The address to check for sell orders
     * @return bool True if the address has listed a sell order, false otherwise
     */
    function orderExistsForAddress(
        Set storage self,
        address listedBy
    ) internal view returns (bool) {
        if (self.keyList.length == 0) return false;
        SellOrder storage o = self.keyList[self.keyPointers[listedBy]];
        return (o.listedBy == listedBy);
    }

    /**
     * Get the sell order at a specific index in the set
     *
     * @param self Set The set of sell orders
     * @param index uint256 The index of the sell order to retrieve
     * @return SellOrder The sell order at the specified index
     */
    function orderAtIndex(
        Set storage self,
        uint256 index
    ) internal view returns (SellOrder storage) {
        return self.keyList[index];
    }

    /**
     * Get the sell order listed by a specific address
     *
     * @param self Set The set of sell orders
     * @param listedBy address The address that listed the sell order to retrieve
     * @return SellOrder The sell order listed by the specified address
     */
    function orderByAddress(
        Set storage self,
        address listedBy
    ) internal view returns (SellOrder storage) {
        return self.keyList[self.keyPointers[listedBy]];
    }

    /**
     * Get the sell order listed by a specific address and category
     *
     * @param self Set The set of sell orders
     * @param listedBy address The address that listed the sell order to retrieve
     * @param category uint8 The category of the sell order to retrieve
     * @return SellOrder The sell order listed by the specified address and category
     */
    function ordersByAddressAndCategory(
        Set storage self,
        address listedBy,
        Category category
    ) internal view validCategory(category) returns (SellOrder[] memory) {
        SellOrder[] memory matchingOrders;
        uint256 iCount = 0;

        for (uint256 i = 0; i < self.keyList.length; i++) {
            if (
                self.keyList[i].listedBy == listedBy &&
                Category(self.keyList[i].category) == category
            ) {
                matchingOrders[iCount] = self.keyList[i];
                iCount++;
            }
        }

        SellOrder[] memory result = new SellOrder[](iCount);
        for (uint256 i = 0; i < iCount; i++) {
            result[i] = matchingOrders[i];
        }

        return result;
    }

    /**
     * Remove all sell orders from the set
     *
     * @param self Set The set of sell orders to nuke
     */
    function nukeSet(Set storage self) public {
        delete self.keyList;
    }

    /**
     * Get all sell orders in the set
     *
     * @param self Set The set of sell orders
     * @return SellOrder[] The array of all sell orders in the set
     */
    function allOrders(
        Set storage self
    ) internal view returns (SellOrder[] storage) {
        return self.keyList;
    }

    /**
     * Get all sell orders in the set by a specific category
     *
     * @param self Set The set of sell orders
     * @param category uint256 The category to filter by
     * @return SellOrder[] The array of all sell orders in the set by a specific category
     */

    function allOrdersByCategory(
        Set storage self,
        Category category
    ) internal view validCategory(category) returns (SellOrder[] memory) {
        SellOrder[] memory matchingOrders;
        uint256 iCount = 0;

        for (uint256 i = 0; i < self.keyList.length; i++) {
            if (Category(self.keyList[i].category) == category) {
                matchingOrders[iCount] = self.keyList[i];
                iCount++;
            }
        }

        SellOrder[] memory result = new SellOrder[](iCount);
        for (uint256 i = 0; i < iCount; i++) {
            result[i] = matchingOrders[i];
        }

        return result;
    }
}
