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

    SteadyEngine steadyEngine;
    SteadyFormula steadyFormula;
    SteadyCoin steadyCoin;
    SteadyMarketplace steadyMarketplace;

    string public vendorName;
    string public vendorDescription;
    string public vendorBusinessRegistrationNumber;
    address public vendorAddress = msg.sender;

    function setUp() public {
        steadyCoin = new SteadyCoin();
        steadyEngine = new SteadyEngine(
            address(steadyCoin),
            address(steadyMarketplace),
            address(steadyFormula)
        );
    }

    function testRegisterVendor() public {
        vm.prank(steadyMarketplace.owner());

        vendorName = "Vendor 1";
        vendorDescription = "Vendor 1 description";
        vendorBusinessRegistrationNumber = "1234567890";

        // Register the vendor
        steadyMarketplace.registerVendor{value: 100 ether}(
            vendorName,
            vendorDescription,
            vendorBusinessRegistrationNumber
        );

        vm.expectRevert();

        // Fetch the vendor's name using the getVendorByAddress function
        address addr = steadyMarketplace
            .getVendorByAddress(vendorAddress)
            .vendorAddress;

        string memory name = steadyMarketplace
            .getVendorByAddress(vendorAddress)
            .vendorName;

        string memory description = steadyMarketplace
            .getVendorByAddress(vendorAddress)
            .vendorDescription;

        string memory businessRegistrationNumber = steadyMarketplace
            .getVendorByAddress(vendorAddress)
            .vendorBusinessRegistrationNumber;

        uint256 dateCreated = steadyMarketplace
            .getVendorByAddress(vendorAddress)
            .dateCreated;

        uint256 dateUpdated = steadyMarketplace
            .getVendorByAddress(vendorAddress)
            .dateUpdated;

        assertEq(addr, vendorAddress);
        assertEq(name, vendorName);
        assertEq(description, vendorDescription);
        assertEq(businessRegistrationNumber, vendorBusinessRegistrationNumber);
        assertEq(dateCreated, dateCreated);
        assertEq(dateUpdated, dateUpdated);

        vm.stopPrank();
    }
}
