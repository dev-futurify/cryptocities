// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*
 * @title SteadyFormula
 * @description Economic formula for the SteadyEngine contract. This contract is deployed separately from
 * SteadyEngine contract to make the economic formula upgradable.
 * @author ricogustavo
 * @team Futurify x EpicStartups
 *
 */

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {OrderSet} from "./libraries/OrderSet.sol";

contract SteadyFormula {
    error SteadyFormula__CategoryMustBeBetween0And7();

    // Use SafeMath library for uint256 arithmetic operations
    using SafeMath for uint256;

    // Use OrderSet for OrderSet.Set operations
    using OrderSet for OrderSet.Set;
    // use OrderSet.Category for OrderSet.Category operations
    using OrderSet for OrderSet.Category;

    modifier validCategory(OrderSet.Category category) {
        if (uint8(category) < 0 || uint8(category) > 7) {
            revert SteadyFormula__CategoryMustBeBetween0And7();
        }
        _;
    }

    /**
     * Get yearly Consumer Price Index (CPI) of the set
     *
     * @param self Set The set of sell orders
     * @return uint256 The Consumer Price Index (CPI) of the set
     */
    function getYearlyCPI(
        OrderSet.Set storage self
    ) internal view returns (uint256) {
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
    function getMonthlyCPI(
        OrderSet.Set storage self
    ) internal view returns (uint256) {
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
        OrderSet.Set storage self
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
        OrderSet.Set storage self
    ) internal view returns (uint256) {
        uint256 newCPI = getMonthlyCPI(self);
        uint256 oldCPI = getMonthlyCPI(self);
        return _getInflationRate(newCPI, oldCPI);
    }

    /**
     * Get the overall sales of tokens being sold in the set
     *
     * @param self Set The set of sell orders
     * @return uint256 The overall sales of tokens being sold in the set
     */
    function _totalSales(
        OrderSet.Set storage self
    ) internal view returns (uint256) {
        uint256 totalCost = 0;
        for (uint256 i = 0; i < self.keyList.length; i++) {
            totalCost += self.keyList[i].quantity * self.keyList[i].unitPrice;
        }
        return totalCost;
    }

    /**
     * Get the total sales of tokens being sold in the set by a specific vendor
     *
     * @param self Set The set of sell orders
     * @param vendor address The vendor to filter by
     * @return uint256 The total sales of tokens being sold in the set by a specific vendor
     */
    function _totalSalesByVendor(
        OrderSet.Set storage self,
        address vendor
    ) internal view returns (uint256) {
        uint256 totalCost = 0;
        for (uint256 i = 0; i < self.keyList.length; i++) {
            if (self.keyList[i].listedBy == vendor) {
                totalCost +=
                    self.keyList[i].quantity *
                    self.keyList[i].unitPrice;
            }
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
        OrderSet.Set storage self,
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
        OrderSet.Set storage self,
        OrderSet.Category category
    ) internal view validCategory(category) returns (uint256) {
        uint256 totalCost = 0;
        for (uint256 i = 0; i < self.keyList.length; i++) {
            if (OrderSet.Category(self.keyList[i].category) == category) {
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
        OrderSet.Set storage self,
        OrderSet.Category category,
        uint256 dateSold
    ) internal view validCategory(category) returns (uint256) {
        uint256 totalCost = 0;
        for (uint256 i = 0; i < self.keyList.length; i++) {
            if (
                OrderSet.Category(self.keyList[i].category) == category &&
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
     * Get the Consumer Price Index (CPI)
     * CPI = (currentCost / priorCost) * 100
     *
     * currentCost = total cost of tokens being sold in the set by a specific date
     * priorCost = total cost of tokens being sold in the set by a specific date
     *
     * @param currentCost uint256 The total cost of tokens being sold in the set by a specific date
     * @param priorCost uint256 The total cost of tokens being sold in the set by a specific date
     * @return uint256 The Consumer Price Index (CPI)
     */
    function _getCPI(
        uint256 currentCost,
        uint256 priorCost
    ) internal pure returns (uint256) {
        return (currentCost / priorCost) * 100;
    }

    /**
     * Get the inflation rate
     * Inflation Rate = ((newCPI - oldCPI) / oldCPI) * 100
     *
     * newCPI = Consumer Price Index (CPI) of the set
     * oldCPI = Consumer Price Index (CPI) of the set
     *
     * @param newCPI uint256 The Consumer Price Index (CPI) of the set
     * @param oldCPI uint256 The Consumer Price Index (CPI) of the set
     * @return uint256 The inflation rate
     */
    function _getInflationRate(
        uint256 newCPI,
        uint256 oldCPI
    ) internal pure returns (uint256) {
        return ((newCPI - oldCPI) / oldCPI) * 100;
    }
}
