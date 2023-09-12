// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {SteadyCoin} from "../../contracts/SteadyCoin.sol";

contract SteadyCoinTest is StdCheats, Test {
    SteadyCoin stc;

    function setUp() public {
        stc = new SteadyCoin();
    }

    function testMustMintMoreThanZero() public {
        vm.prank(stc.owner());
        vm.expectRevert();
        stc.mint(address(this), 0);
    }

    function testMustBurnMoreThanZero() public {
        vm.startPrank(stc.owner());
        stc.mint(address(this), 100);
        vm.expectRevert();
        stc.burn(0);
        vm.stopPrank();
    }

    function testCantBurnMoreThanYouHave() public {
        vm.startPrank(stc.owner());
        stc.mint(address(this), 100);
        vm.expectRevert();
        stc.burn(101);
        vm.stopPrank();
    }

    function testCantMintToZeroAddress() public {
        vm.startPrank(stc.owner());
        vm.expectRevert();
        stc.mint(address(0), 100);
        vm.stopPrank();
    }
}
