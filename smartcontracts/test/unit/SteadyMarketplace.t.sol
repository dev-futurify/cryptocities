// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {SteadyFormula} from "../../contracts/SteadyFormula.sol";
import {SteadyCoin} from "../../contracts/SteadyCoin.sol";
import {SteadyMarketplace} from "../../contracts/SteadyMarketplace.sol";
import {OrderSet} from "../../contracts/libraries/OrderSet.sol";

contract SteadyMarketplaceTest is Test {
    error SteadyMarketplace__OnlyVendor();

    using OrderSet for OrderSet.Set;

    SteadyFormula steadyFormula;
    SteadyCoin steadyCoin;
    SteadyMarketplace steadyMarketplace;

    address public vendorAddress = msg.sender;
    uint256 public vendorIdCounter = 1;
    uint256 public storeIdCounter = 1;

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
        // Name of the store
        string storeName,
        // Description of the store
        string storeDescription,
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
            vendorName,
            vendorDescription,
            vendorBusinessRegistrationNumber
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

        uint256 id = steadyMarketplace
            .getVendorByAddress(vendorAddress)
            .vendorId;

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

        // assertion of the vendor creation
        assertEq(id, vendorIdCounter);
        assertEq(addr, vendorAddress);
        assertEq(name, vendorName);
        assertEq(description, vendorDescription);
        assertEq(businessRegistrationNumber, vendorBusinessRegistrationNumber);

        // Update the vendor
        string memory newVendorName = "Vendor 1 updated";
        string memory newVendorDescription = "Vendor 1 description updated";
        string
            memory newVendorBusinessRegistrationNumber = "FT 1234567890 updated";
        uint256 newDateUpdated = block.timestamp;

        steadyMarketplace.updateVendor(
            vendorAddress,
            vendorIdCounter,
            newVendorName,
            newVendorDescription,
            newVendorBusinessRegistrationNumber
        );

        emit VendorUpdated(
            vendorAddress,
            vendorIdCounter,
            newVendorName,
            newVendorDescription,
            newVendorBusinessRegistrationNumber,
            newDateUpdated
        );

        string memory storeName = "Store 1";
        string memory storeDescription = "Store 1 description";
        OrderSet.Category storeCategory = OrderSet.Category.Transportation;
        uint256 stNewDate = block.timestamp;

        steadyMarketplace.registerVendorStore(
            storeName,
            storeDescription,
            storeCategory
        );

        emit VendorStoreCreated(
            storeIdCounter,
            vendorAddress,
            address(steadyMarketplace),
            storeName,
            storeDescription,
            storeCategory,
            stNewDate,
            stNewDate
        );

        address storeAddress = steadyMarketplace
            .getVendorStoreByVendorAddress(vendorAddress)
            .storeAddress;

        console.log("storeAddress", storeAddress);

        uint256 storeId = steadyMarketplace
            .getVendorStoreByVendorAddress(vendorAddress)
            .storeId;

        console.log("storeId", storeId);

        address vendorAddr = steadyMarketplace
            .getVendorStoreByVendorAddress(vendorAddress)
            .vendorAddress;

        console.log("vendorAddr", vendorAddr);

        string memory stName = steadyMarketplace
            .getVendorStoreByVendorAddress(vendorAddress)
            .storeName;

        console.log("stName", stName);

        string memory stDesc = steadyMarketplace
            .getVendorStoreByVendorAddress(vendorAddress)
            .storeDescription;

        console.log("stDesc", stDesc);

        OrderSet.Category stCat = steadyMarketplace
            .getVendorStoreByVendorAddress(vendorAddress)
            .category;

        assertEq(storeId, storeIdCounter);
        assertEq(vendorAddr, vendorAddress);
        assertEq(stName, storeName);
        assertEq(stDesc, storeDescription);
        assertTrue(stCat == storeCategory);

        vm.stopPrank();
    }

    // this needs to be inside the vendor mechanism as well as only vendor and has store can call these functions
    function testCreateSellOrderMechanism() public {}

    function testCancelSellorderMechanism() public {}

    function testCreateBuyOrderMechanism() public {}

    function testVendorWithdrawalMechanism() public {}

    function testOwnerWithdrawalMechanism() public {}
}
