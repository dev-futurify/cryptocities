// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {SteadyEngine} from "../../contracts/SteadyEngine.sol";
import {SteadyFormula} from "../../contracts/SteadyFormula.sol";
import {SteadyCoin} from "../../contracts/SteadyCoin.sol";
import {SteadyMarketplace} from "../../contracts/SteadyMarketplace.sol";
import {OrderSet} from "../../contracts/libraries/OrderSet.sol";

contract SteadyMarketplaceTest is Test {
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
}
