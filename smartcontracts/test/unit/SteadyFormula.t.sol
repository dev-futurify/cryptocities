// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {SteadyFormula} from "../../contracts/SteadyFormula.sol";
import {OrderSet} from "../../contracts/libraries/OrderSet.sol";

contract SteadyFormulaTest is Test {
    using OrderSet for OrderSet.Set;

    SteadyFormula private steadyFormula;
    OrderSet.Set private orderSet;

    mapping(uint256 => OrderSet.Set) private orders;

    function setUp() public {
        steadyFormula = new SteadyFormula();
    }
}
