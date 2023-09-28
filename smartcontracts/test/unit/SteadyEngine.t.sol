// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {SteadyEngine} from "../../contracts/SteadyEngine.sol";
import {SteadyFormula} from "../../contracts/SteadyFormula.sol";
import {SteadyCoin} from "../../contracts/SteadyCoin.sol";
import {SteadyMarketplace} from "../../contracts/SteadyMarketplace.sol";
import {OrderSet} from "../../contracts/libraries/OrderSet.sol";
import {MockCPI} from "../mocks/MockCPI.t.sol";
import {MockIR} from "../mocks/MockIR.t.sol";

contract SteadyMarketplaceTest is StdCheats, Test {
    event CollateralRedeemed(address indexed redeemFrom, address indexed redeemTo, address token, uint256 amount); // if redeemFrom != redeemedTo, then it was liquidated

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;
    uint256 public deployerKey;

    uint256 amountCollateral = 10 ether;
    uint256 amountToMint = 100 ether;
    address public user = address(1);

    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;
    uint256 public constant LIQUIDATION_THRESHOLD = 50;

    // Liquidation
    address public liquidator = makeAddr("liquidator");
    uint256 public collateralToCover = 20 ether;

    using OrderSet for OrderSet.Set;

    SteadyEngine private steadyEngine;
    SteadyFormula private steadyFormula;
    SteadyCoin private steadyCoin;
    SteadyMarketplace private steadyMarketplace;

    function setUp() public {
        steadyCoin = new SteadyCoin();
        steadyEngine = new SteadyEngine(
            address(steadyCoin),
            address(steadyMarketplace),
            address(steadyFormula)
        );
        steadyMarketplace = new SteadyMarketplace(address(steadyFormula));
    }

    ///////////////////////
    // Constructor Tests //
    ///////////////////////

    ///////////////////////////////////////
    // depositCollateralAndMintStc Tests //
    ///////////////////////////////////////

    ///////////////////////////////////
    // mintStc Tests //
    ///////////////////////////////////

    ///////////////////////////////////
    // burnStc Tests //
    ///////////////////////////////////

    function testCantBurnMoreThanUserHas() public {
        vm.prank(user);
        vm.expectRevert();
        steadyEngine.burnStc(1);
    }

    ///////////////////////////////////
    // redeemCollateral Tests //
    //////////////////////////////////

    ///////////////////////////////////
    // redeemCollateralForStc Tests //
    //////////////////////////////////

    ///////////////////////
    // Liquidation Tests //
    ///////////////////////

    ///////////////////////////////////
    // View & Pure Function Tests //
    //////////////////////////////////
}
