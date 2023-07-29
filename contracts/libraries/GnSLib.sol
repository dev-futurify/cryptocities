// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*
 * @title GnSLib - Good and Services Library
 * @author ricogustavo
 * @team Futurify x EpicStartups
 * @notice This library is used to check the Chainlink Oracle for stale data of the "baskets".
 * If a price is stale, functions will revert, and render the SteadyEngine unusable - this is by design.
 * We want the SteadyEngine to freeze if prices become stale.
 *
 */
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library GnSLib {
    error GnSLib__StalePrice();

    uint256 private constant TIMEOUT = 3 hours;

    function staleCheckLatestRoundData(
        address aggregatorAddress
    ) external view returns (uint80, int256, uint256, uint256, uint80) {
        AggregatorV3Interface baskets = AggregatorV3Interface(
            // @add: address of "baskets" w/ ERC1155
            aggregatorAddress
        );

        (
            uint80 roundID,
            int nftFloorPrice,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = baskets.latestRoundData();

        if (timeStamp == 0 || answeredInRound < roundID) {
            revert GnSLib__StalePrice();
        }

        uint256 secondsSince = block.timestamp - timeStamp;
        if (secondsSince > TIMEOUT) revert GnSLib__StalePrice();

        return (roundID, nftFloorPrice, startedAt, timeStamp, answeredInRound);
    }

    function getTimeout(AggregatorV3Interface) public pure returns (uint256) {
        return TIMEOUT;
    }
}
