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
        require(
            uint8(category) >= 0 && uint8(category) <= 7,
            "OrderSetLib(99) - Category must be between 0 and 7"
        );
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
        require(
            uint8(key.category) >= 0 && uint8(key.category) <= 11,
            "OrderSetLib(104) - Category must be between 0 and 11"
        );
        // Check if the dateSold is block.timestamp.
        require(
            key.dateSold == block.timestamp,
            "OrderSetLib(105) - Date sold must be block.timestamp"
        );

        // If all checks pass, add the SellOrder to the keyList array.
        self.keyList.push(key);
        // Update the keyPointers mapping with the index of the newly added SellOrder.
        self.keyPointers[key.listedBy] = self.keyList.length - 1;
    }

    function remove(
        Set storage self,
        SellOrder memory key
    ) internal validCategory(Category(key.category)) {
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

    /**
     * Consumer Price Index (CPI) formula
     * CPI_t	=   consumer price index in current period
     * C_t	    =	cost of market basket in current period
     * C_0	    =	cost of market basket in base period
     *  where current period  = current year
     *  where base period     = prior year
     */

    /**
     * Get yearly Consumer Price Index (CPI) of the set
     *
     * @param self Set The set of sell orders
     * @return uint256 The Consumer Price Index (CPI) of the set
     */
    function getYearlyCPI(Set storage self) internal view returns (uint256) {
        uint256 currentCost = _totalSalesByDate(self, block.timestamp);
        uint256 priorCost = _totalSalesByDate(self, block.timestamp - 365 days);
        return _getCPI(currentCost, priorCost);
    }

    /**
     * Get monthly Consumer Price Index (CPI) of the set
     *
     * @param self Set The set of sell orders
     * @return uint256 The Consumer Price Index (CPI) of the set
     */
    function getMonthlyCPI(Set storage self) internal view returns (uint256) {
        uint256 currentCost = _totalSalesByDate(self, block.timestamp);
        uint256 priorCost = _totalSalesByDate(self, block.timestamp - 30 days);
        return _getCPI(currentCost, priorCost);
    }

    /**
     * Get yearly inflation rate of the set
     *
     * @param self Set The set of sell orders
     * @return uint256 The yearly inflation rate of the set
     */
    function getYearlyInflationRate(
        Set storage self
    ) internal view returns (uint256) {
        uint256 newCPI = getYearlyCPI(self);
        uint256 oldCPI = getYearlyCPI(self);
        return _getInflationRate(newCPI, oldCPI);
    }

    /**
     * Get monthly inflation rate of the set
     *
     * @param self Set The set of sell orders
     * @return uint256 The monthly inflation rate of the set
     */
    function getMonthlyInflationRate(
        Set storage self
    ) internal view returns (uint256) {
        uint256 newCPI = getMonthlyCPI(self);
        uint256 oldCPI = getMonthlyCPI(self);
        return _getInflationRate(newCPI, oldCPI);
    }

    /**
     * Get overall total sales of tokens being sold in the set
     *
     * @param self Set The set of sell orders
     * @return uint256 The total sales of tokens being sold in the set
     */
    function _totalSales(Set storage self) internal view returns (uint256) {
        uint256 totalCost = 0;
        for (uint256 i = 0; i < self.keyList.length; i++) {
            totalCost += self.keyList[i].quantity * self.keyList[i].unitPrice;
        }
        return totalCost;
    }

    /**
     * Get the total sales of tokens being sold in the set by a specific date
     *
     * @param self Set The set of sell orders
     * @param dateSold string The date to filter by
     * @return uint256 The total sales of tokens being sold in the set by a specific date
     */
    function _totalSalesByDate(
        Set storage self,
        uint256 dateSold
    ) internal view returns (uint256) {
        uint256 totalCost = 0;
        for (uint256 i = 0; i < self.keyList.length; i++) {
            if (
                keccak256(abi.encodePacked(self.keyList[i].dateSold)) ==
                keccak256(abi.encodePacked(dateSold))
            ) {
                totalCost +=
                    self.keyList[i].quantity *
                    self.keyList[i].unitPrice;
            }
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
    function _totalSalesByCategory(
        Set storage self,
        Category category
    ) internal view validCategory(category) returns (uint256) {
        uint256 totalCost = 0;
        for (uint256 i = 0; i < self.keyList.length; i++) {
            if (Category(self.keyList[i].category) == category) {
                totalCost +=
                    self.keyList[i].quantity *
                    self.keyList[i].unitPrice;
            }
        }
        return totalCost;
    }

    /**
     * Get the total cost of tokens being sold in the set by a specific category and date
     *
     * @param self Set The set of sell orders
     * @param category uint256 The category to filter by
     * @param dateSold string The date to filter by
     * @return uint256 The total cost of tokens being sold in the set by a specific category and date
     */
    function _totalSalesByCategoryAndDate(
        Set storage self,
        Category category,
        uint256 dateSold
    ) internal view validCategory(category) returns (uint256) {
        uint256 totalCost = 0;
        for (uint256 i = 0; i < self.keyList.length; i++) {
            if (
                Category(self.keyList[i].category) == category &&
                keccak256(abi.encodePacked(self.keyList[i].dateSold)) ==
                keccak256(abi.encodePacked(dateSold))
            ) {
                totalCost +=
                    self.keyList[i].quantity *
                    self.keyList[i].unitPrice;
            }
        }
        return totalCost;
    }

    // get consumer price index (CPI)
    function _getCPI(
        uint256 currentCost,
        uint256 priorCost
    ) internal pure returns (uint256) {
        return (currentCost / priorCost) * 100;
    }

    // get inflation rate
    function _getInflationRate(
        uint256 newCPI,
        uint256 oldCPI
    ) internal pure returns (uint256) {
        return ((newCPI - oldCPI) / oldCPI) * 100;
    }
}
