// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
 * @title SellOrderSetLib - Sell Order Set Library
 * @author ricogustavo
 * @team Futurify x EpicStartups
 * @notice Reference to the Hitchens UnorderedKeySet library version 0.93
 * https://github.com/rob-Hitchens/UnorderedKeySet
 *
 */

library SellOrderSetLib {
    // Category enum representing the category of a sell order.
    enum Category {
        FoodAndNonAlcoholicBeverages,
        RestaurantsAndHotels,
        AlcoholicBeveragesAndTobacco,
        ClothingAndFootwear,
        HousingWaterElectricityGasAndOtherFuels,
        FurnishingsHouseholdEquipmentAndRoutineHouseholdMaintenance,
        Health,
        Transport,
        Communication,
        RecreationServicesAndCulture,
        Education,
        MiscGoodsAndServices
    }

    modifier validCategory(uint8 category) {
        require(
            category > 0 && category < 13,
            "SellOrderSetLib(100) - Category must be between 1 and 12."
        );
        _;
    }

    // SellOrder structure representing a sell order, containing the address of the seller, the quantity of tokens being sold, and the unit price of the tokens.
    struct SellOrder {
        address listedBy; // Address of the seller
        uint256 quantity; // Quantity of tokens being sold
        uint256 unitPrice; // Unit price of the tokens
        Category category; // Category of the sell order
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
    ) internal validCategory(uint8(key.category)) {
        // Check if the seller address is address(0), which is not allowed.
        require(
            key.listedBy != address(0),
            "OrderSetLib(100) - Sell Order cannot be listed by address(0)"
        );
        // Check if the quantity of tokens being sold is greater than 0.
        require(
            key.quantity > 0,
            "OrderSetLib(101) - Sell Order cannot have 0 token count"
        );
        // Check if the unit price of the tokens is greater than 0.
        require(
            key.unitPrice > 0,
            "OrderSetLib(102) - Sell Order cannot have 0 token price"
        );
        // Check if the SellOrder is already in the Set.
        require(
            !exists(self, key),
            "OrderSetLib(103) - Key already exists in the set."
        );
        // Check if the category is between 1 and 12.

        // If all checks pass, add the SellOrder to the keyList array.
        self.keyList.push(key);
        // Update the keyPointers mapping with the index of the newly added SellOrder.
        self.keyPointers[key.listedBy] = self.keyList.length - 1;
    }

    function remove(
        Set storage self,
        SellOrder memory key
    ) internal validCategory(uint8(key.category)) {
        require(
            exists(self, key),
            "OrderSetLib(104) - Sell Order does not exist in the set."
        );

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
        uint8 category
    ) internal view validCategory(category) returns (SellOrder[] memory) {
        SellOrder[] memory matchingOrders;
        uint256 iCount = 0;

        for (uint256 i = 0; i < self.keyList.length; i++) {
            if (
                self.keyList[i].listedBy == listedBy &&
                uint8(self.keyList[i].category) == category
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
        uint8 category
    ) internal view validCategory(category) returns (SellOrder[] memory) {
        SellOrder[] memory matchingOrders;
        uint256 iCount = 0;

        for (uint256 i = 0; i < self.keyList.length; i++) {
            if (uint8(self.keyList[i].category) == category) {
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
     * Get the total cost of tokens being sold in the set
     *
     * @param self Set The set of sell orders
     * @return uint256 The total cost of tokens being sold in the set
     */
    function totalSales(Set storage self) internal view returns (uint256) {
        uint256 totalCost = 0;
        for (uint256 i = 0; i < self.keyList.length; i++) {
            totalCost += self.keyList[i].quantity * self.keyList[i].unitPrice;
        }
        return totalCost;
    }

    /**
     * Get the total cost of tokens being sold in the set by a specific category
     *
     * @param self Set The set of sell orders
     * @param category uint256 The category to filter by
     * @return uint256 The total cost of tokens being sold in the set by a specific category
     */
    function totalSalesByCategory(
        Set storage self,
        uint8 category
    ) internal view validCategory(category) returns (uint256) {
        uint256 totalCost = 0;
        for (uint256 i = 0; i < self.keyList.length; i++) {
            if (uint8(self.keyList[i].category) == category) {
                totalCost +=
                    self.keyList[i].quantity *
                    self.keyList[i].unitPrice;
            }
        }
        return totalCost;
    }
}
