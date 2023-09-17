// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {SteadyFormula} from "../../contracts/SteadyFormula.sol";
import {SteadyCoin} from "../../contracts/SteadyCoin.sol";
import {SteadyMarketplace} from "../../contracts/SteadyMarketplace.sol";
import {OrderSet} from "../../contracts/libraries/OrderSet.sol";

contract SteadyMarketplaceTest is Test {
    using OrderSet for OrderSet.Set;

    SteadyFormula steadyFormula;
    SteadyCoin steadyCoin;
    SteadyMarketplace steadyMarketplace;

    address public vendorAddress = msg.sender;
    uint256 public vendorIdCounter = 1;

    // Event when new vendor is created
    // Account address of the vendor
    event VendorCreated(
        address vendorAddress,
        // Id of the vendor
        uint256 vendorId,
        // Name of the vendor
        string vendorName,
        // Description of the vendor
        string vendorDescription,
        // Date when the vendor was created
        // Business registration number of the vendor
        string vendorBusinessRegistrationNumber,
        uint256 dateCreated,
        // Date when the vendor was updated
        uint256 dateUpdated
    );

    // Event when vendor is updated
    // Account address of the vendor
    event VendorUpdated(
        address vendorAddress,
        // Id of the vendor
        uint256 vendorId,
        // Name of the vendor
        string vendorName,
        // Description of the vendor
        string vendorDescription,
        // Business registration number of the vendor
        string vendorBusinessRegistrationNumber,
        // Date when the vendor was updated
        uint256 dateUpdated
    );

    // Event when new vendor store is created
    // store id of the vendor
    event VendorStoreCreated(
        uint256 storeId,
        // Account address of the vendor
        address vendorAddress,
        // store address of the vendor
        address storeAddress,
        // Name of the vendor
        string vendorName,
        // Description of the vendor
        string vendorDescription,
        // Category of the item
        OrderSet.Category category,
        // Date when the vendor was created
        uint256 dateCreated,
        // Date when the vendor was updated
        uint256 dateUpdated
    );

    // Event when vendor store is updated
    // Account address of the vendor
    event VendorStoreUpdated(
        address vendorAddress,
        // store id of the vendor
        uint256 storeId,
        // store address of the vendor
        address storeAddress,
        // Name of the vendor
        string vendorName,
        // Description of the vendor
        string vendorDescription,
        // Date when the vendor was updated
        uint256 dateUpdated
    );

    // Event to indicate a token is listed for sale
    // Account address of the token owner
    event ListedForSale(
        address account,
        // market order id
        uint256 orderId,
        // Number of tokens for sale
        uint256 noOfTokensForSale,
        // Unit price of each token
        uint256 unitPrice,
        // Category of the item
        OrderSet.Category category,
        // Date when the item was created
        uint256 date
    );

    // Event to indicate a token is unlisted from sale
    // Account address of the token owner
    event UnlistedFromSale(
        address account,
        // market order id
        uint256 orderId
    );

    // Event to indicate a token is sold
    // Account address of the token seller
    event ItemSold(
        address from,
        // Account address of the token buyer
        address to,
        // market order id
        uint256 orderId,
        // Number of tokens sold
        uint256 tokenCount,
        // Purchase amount
        uint256 puchaseAmount
    );

    function setUp() public {
        steadyFormula = new SteadyFormula();
        steadyCoin = new SteadyCoin();
        steadyMarketplace = new SteadyMarketplace(address(steadyFormula));
    }

    function testVendorMechanism() public {
        vm.startPrank(vendorAddress);

        string memory vendorName = "Vendor 1";
        string memory vendorDescription = "Vendor 1 description";
        string memory vendorBusinessRegistrationNumber = "FT 1234567890";
        uint256 newDate = block.timestamp;

        steadyMarketplace.registerVendor{value: 100 ether}(
            vendorName, vendorDescription, vendorBusinessRegistrationNumber
        );

        emit VendorCreated(
            vendorAddress,
            vendorIdCounter,
            vendorName,
            vendorDescription,
            vendorBusinessRegistrationNumber,
            newDate,
            newDate
        );

        uint256 id = steadyMarketplace.getVendorByAddress(vendorAddress).vendorId;

        address addr = steadyMarketplace.getVendorByAddress(vendorAddress).vendorAddress;

        string memory name = steadyMarketplace.getVendorByAddress(vendorAddress).vendorName;

        string memory description = steadyMarketplace.getVendorByAddress(vendorAddress).vendorDescription;

        string memory businessRegistrationNumber =
            steadyMarketplace.getVendorByAddress(vendorAddress).vendorBusinessRegistrationNumber;

        uint256 dateCreated = steadyMarketplace.getVendorByAddress(vendorAddress).dateCreated;

        uint256 dateUpdated = steadyMarketplace.getVendorByAddress(vendorAddress).dateUpdated;

        // assertion of the vendor creation
        assertEq(id, vendorIdCounter);
        assertEq(addr, vendorAddress);
        assertEq(name, vendorName);
        assertEq(description, vendorDescription);
        assertEq(businessRegistrationNumber, vendorBusinessRegistrationNumber);
        assertEq(dateCreated, dateCreated);
        assertEq(dateUpdated, dateUpdated);

        // Update the vendor
        string memory newVendorName = "Vendor 1 updated";
        string memory newVendorDescription = "Vendor 1 description updated";
        string memory newVendorBusinessRegistrationNumber = "FT 1234567890 updated";
        uint256 newDateUpdated = block.timestamp;

        steadyMarketplace.updateVendor(
            vendorAddress, vendorIdCounter, newVendorName, newVendorDescription, newVendorBusinessRegistrationNumber
        );

        emit VendorUpdated(
            vendorAddress,
            vendorIdCounter,
            newVendorName,
            newVendorDescription,
            newVendorBusinessRegistrationNumber,
            newDateUpdated
        );

        vm.stopPrank();
    }

    function testVendorStoreMechanism() public {}

    function testCreateSellOrderMechanism() public {}

    function testCancelSellorderMechanism() public {}

    function testCreateBuyOrderMechanism() public {}

    function testVendorWithdrawalMechanism() public {}

    function testOwnerWithdrawalMechanism() public {}
}
