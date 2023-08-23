import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";

describe("SteadyCoin", () => {
  let steadyCoin: any;
  let owner: any;
  let addr1: any;
  let addr2: any;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy the SteadyCoin contract
    const SteadyCoinFactory = await ethers.getContractFactory("SteadyCoin");
    steadyCoin = await SteadyCoinFactory.deploy();
    await steadyCoin.deployed();

    // Mint some initial tokens for testing
    await steadyCoin.mint(owner.address, ethers.utils.parseEther("1000"));
  });

  it("Should have correct name, symbol, and initial supply", async function () {
    expect(await steadyCoin.name()).to.equal("SteadyCoin");
    expect(await steadyCoin.symbol()).to.equal("STC");
    expect(await steadyCoin.totalSupply()).to.equal(
      ethers.utils.parseEther("1000")
    );
  });

  it("Should mint tokens", async function () {
    await steadyCoin.mint(addr1.address, ethers.utils.parseEther("500"));
    expect(await steadyCoin.balanceOf(addr1.address)).to.equal(
      ethers.utils.parseEther("500")
    );
  });

  it("Should not mint tokens to zero address", async function () {
    await expect(
      steadyCoin.mint(
        ethers.constants.AddressZero,
        ethers.utils.parseEther("500")
      )
    ).to.be.revertedWith("SteadyCoin__NotZeroAddress");
  });

  it("Should not mint tokens with zero amount", async function () {
    await expect(steadyCoin.mint(addr1.address, 0)).to.be.revertedWith(
      "SteadyCoin__AmountMustBeMoreThanZero"
    );
  });

  it("Should burn tokens", async function () {
    await steadyCoin.burn(ethers.utils.parseEther("200"));
    expect(await steadyCoin.balanceOf(owner.address)).to.equal(
      ethers.utils.parseEther("800")
    );
  });

  it("Should not burn tokens with zero amount", async function () {
    await expect(steadyCoin.burn(0)).to.be.revertedWith(
      "SteadyCoin__AmountMustBeMoreThanZero"
    );
  });

  it("Should not burn tokens more than balance", async function () {
    await expect(
      steadyCoin.burn(ethers.utils.parseEther("1200"))
    ).to.be.revertedWith("SteadyCoin__BurnAmountExceedsBalance");
  });
});

describe("SteadyMarketplace", () => {
  let marketplace: Contract;
  let deployer: Signer;
  let vendor1: Signer;
  let buyer: Signer;

  beforeEach(async () => {
    [deployer, vendor1, buyer] = await ethers.getSigners();

    const Marketplace = await ethers.getContractFactory("SteadyMarketplace");
    marketplace = await Marketplace.deploy();
    await marketplace.deployed();
  });

  it("should allow deployment", async () => {
    // Ensure the contract is successfully deployed
    expect(marketplace.address).to.not.equal(ethers.constants.AddressZero);
  });

  // Test cases for vendor registration
  describe("Vendor Registration", () => {
    it("should register a new vendor", async () => {
      // Register a new vendor
      const vendorName = "Vendor1";
      const vendorDescription = "Vendor 1 description";
      await marketplace
        .connect(vendor1)
        .registerVendor(vendorName, vendorDescription);

      // Verify that the vendor is registered
      const vendor = await marketplace.vendors(await vendor1.getAddress());
      expect(vendor.vendorAddress).to.equal(await vendor1.getAddress());
      expect(vendor.vendorName).to.equal(vendorName);
      expect(vendor.vendorDescription).to.equal(vendorDescription);
    });

    it("should update vendor details", async () => {
      // Register a new vendor
      const vendorName = "Vendor1";
      const vendorDescription = "Vendor 1 description";
      await marketplace
        .connect(vendor1)
        .registerVendor(vendorName, vendorDescription);

      // Update vendor details
      const newVendorName = "Updated Vendor1";
      const newVendorDescription = "Updated Vendor 1 description";
      await marketplace
        .connect(vendor1)
        .updateVendor(newVendorName, newVendorDescription);

      // Verify that the vendor details are updated
      const updatedVendor = await marketplace.vendors(
        await vendor1.getAddress()
      );
      expect(updatedVendor.vendorName).to.equal(newVendorName);
      expect(updatedVendor.vendorDescription).to.equal(newVendorDescription);
    });

    it("should not allow non-vendors to update vendor details", async () => {
      // Try to update vendor details from a non-vendor account
      await expect(
        marketplace.updateVendor("New Name", "New Description")
      ).to.be.revertedWith("Only registered vendors can perform this action.");
    });
  });

  // Test cases for vendor collection registration
  describe("Vendor Collection", () => {
    it("should register a new vendor collection", async () => {
      // Register a new vendor
      const vendorName = "Vendor1";
      const vendorDescription = "Vendor 1 description";
      await marketplace
        .connect(vendor1)
        .registerVendor(vendorName, vendorDescription);

      // Register a new vendor collection
      const collectionId = 1;
      const collectionAddress = await vendor1.getAddress(); // This could be a unique address for each collection
      const category = 1;
      const collectionName = "Collection 1";
      const collectionDescription = "Collection 1 description";
      await marketplace
        .connect(vendor1)
        .registerVendorCollection(
          collectionId,
          collectionAddress,
          category,
          collectionName,
          collectionDescription
        );

      // Verify that the vendor collection is registered
      const vendorCollection = await marketplace.vendorCollections(
        collectionAddress
      );
      expect(vendorCollection.collectionId).to.equal(collectionId);
      expect(vendorCollection.collectionAddress).to.equal(collectionAddress);
      expect(vendorCollection.category).to.equal(category);
      expect(vendorCollection.collectionName).to.equal(collectionName);
      expect(vendorCollection.collectionDescription).to.equal(
        collectionDescription
      );
    });

    it("should not allow non-vendors to register a collection", async () => {
      // Try to register a vendor collection from a non-vendor account
      await expect(
        marketplace.registerVendorCollection(
          1,
          await vendor1.getAddress(),
          1,
          "Collection 1",
          "Collection 1 description"
        )
      ).to.be.revertedWith("Only registered vendors can perform this action.");
    });
  });

  // Test cases for creating and cancelling sell orders
  describe("Sell Orders", () => {
    let vendorCollectionAddress: string;

    beforeEach(async () => {
      // Register a new vendor
      const vendorName = "Vendor1";
      const vendorDescription = "Vendor 1 description";
      await marketplace
        .connect(vendor1)
        .registerVendor(vendorName, vendorDescription);

      // Register a new vendor collection
      const collectionId = 1;
      vendorCollectionAddress = await vendor1.getAddress(); // This could be a unique address for each collection
      const category = 1;
      const collectionName = "Collection 1";
      const collectionDescription = "Collection 1 description";
      await marketplace
        .connect(vendor1)
        .registerVendorCollection(
          collectionId,
          vendorCollectionAddress,
          category,
          collectionName,
          collectionDescription
        );
    });

    it("should create a sell order and list NFT for sale", async () => {
      const nftId = 1;
      const contractAddress = vendorCollectionAddress;
      const nftType = "erc721";
      const unitPrice = ethers.utils.parseEther("1"); // 1 Ether
      const noOfTokensForSale = 1;
      const category = 1;

      // Create a sell order
      await marketplace
        .connect(vendor1)
        .createSellOrder(
          nftId,
          contractAddress,
          nftType,
          unitPrice,
          noOfTokensForSale,
          category
        );

      // Get sell orders for the NFT
      const sellOrders = await marketplace.getOrders(nftId, contractAddress);
      expect(sellOrders.length).to.equal(1);
      expect(sellOrders[0].listedBy).to.equal(await vendor1.getAddress());
      expect(sellOrders[0].quantity).to.equal(noOfTokensForSale);
      expect(sellOrders[0].unitPrice).to.equal(unitPrice);
      expect(sellOrders[0].category).to.equal(category);
    });

    it("should not allow non-vendors to create a sell order", async () => {
      await expect(
        marketplace.createSellOrder(
          1,
          vendorCollectionAddress,
          "erc721",
          ethers.utils.parseEther("1"),
          1,
          1
        )
      ).to.be.revertedWith("Only registered vendors can perform this action.");
    });

    it("should cancel a sell order", async () => {
      const nftId = 1;
      const contractAddress = vendorCollectionAddress;
      const nftType = "erc721";
      const unitPrice = ethers.utils.parseEther("1"); // 1 Ether
      const noOfTokensForSale = 1;
      const category = 1;

      // Create a sell order
      await marketplace
        .connect(vendor1)
        .createSellOrder(
          nftId,
          contractAddress,
          nftType,
          unitPrice,
          noOfTokensForSale,
          category
        );

      // Cancel the sell order
      await marketplace
        .connect(vendor1)
        .cancelSellOrder(nftId, contractAddress);

      // Get sell orders for the NFT
      const sellOrders = await marketplace.getOrders(nftId, contractAddress);
      expect(sellOrders.length).to.equal(0);
    });

    it("should not allow non-vendors to cancel a sell order", async () => {
      await expect(
        marketplace.cancelSellOrder(1, vendorCollectionAddress)
      ).to.be.revertedWith("Only registered vendors can perform this action.");
    });
  });

  // Add more test cases for buying NFTs, vendor withdrawals, and more functionalities here.
});

describe("SteadyEngine", () => {
  let SteadyEngine;
  let SteadyCoin;
  let steadyEngine;
  let steadyCoin;
  let owner;
  let addr1;
  let addr2;
  let tokenCollateralAddress;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy the SteadyCoin contract
    SteadyCoin = await ethers.getContractFactory("SteadyCoin");
    steadyCoin = await SteadyCoin.deploy();
    await steadyCoin.deployed();

    // Deploy the SteadyEngine contract
    SteadyEngine = await ethers.getContractFactory("SteadyEngine");
    steadyEngine = await SteadyEngine.deploy(
      steadyCoin.address,
      ethers.constants.AddressZero
    );
    await steadyEngine.deployed();

    // Set tokenCollateralAddress for testing
    tokenCollateralAddress = ethers.utils.getAddress(
      "0x1234567890123456789012345678901234567890"
    );
  });

  it("Should deposit collateral and mint STC", async function () {
    const amountCollateral = ethers.utils.parseEther("10");
    const amountStcToMint = ethers.utils.parseEther("100");

    // Deposit collateral and mint STC
    await steadyEngine.depositCollateralAndMintStc(
      tokenCollateralAddress,
      amountCollateral,
      amountStcToMint
    );

    // Check STC balance of the owner
    expect(await steadyCoin.balanceOf(owner.address)).to.equal(amountStcToMint);
  });

  it("Should redeem collateral and burn STC", async function () {
    const amountCollateral = ethers.utils.parseEther("10");
    const amountStcToMint = ethers.utils.parseEther("100");
    const amountStcToBurn = ethers.utils.parseEther("50");

    // Deposit collateral and mint STC
    await steadyEngine.depositCollateralAndMintStc(
      tokenCollateralAddress,
      amountCollateral,
      amountStcToMint
    );

    // Redeem collateral and burn STC
    await steadyEngine.redeemCollateralForStc(
      tokenCollateralAddress,
      amountCollateral,
      amountStcToBurn
    );

    // Check STC balance of the owner
    expect(await steadyCoin.balanceOf(owner.address)).to.equal(
      amountStcToMint.sub(amountStcToBurn)
    );
  });

  it("Should redeem collateral without burning STC", async function () {
    const amountCollateral = ethers.utils.parseEther("10");
    const amountStcToMint = ethers.utils.parseEther("100");

    // Deposit collateral and mint STC
    await steadyEngine.depositCollateralAndMintStc(
      tokenCollateralAddress,
      amountCollateral,
      amountStcToMint
    );

    // Redeem collateral without burning STC
    await steadyEngine.redeemCollateral(
      tokenCollateralAddress,
      amountCollateral
    );

    // Check STC balance of the owner
    expect(await steadyCoin.balanceOf(owner.address)).to.equal(amountStcToMint);
  });

  it("Should liquidate a user", async function () {
    // Implement this test case if needed
  });

  it("Should burn STC", async function () {
    const amountStcToMint = ethers.utils.parseEther("100");
    const amountStcToBurn = ethers.utils.parseEther("50");

    // Deposit collateral and mint STC
    await steadyEngine.depositCollateralAndMintStc(
      tokenCollateralAddress,
      ethers.utils.parseEther("10"),
      amountStcToMint
    );

    // Burn STC
    await steadyEngine.burnStc(amountStcToBurn);

    // Check STC balance of the owner
    expect(await steadyCoin.balanceOf(owner.address)).to.equal(
      amountStcToMint.sub(amountStcToBurn)
    );
  });

  it("Should get the health factor", async function () {
    // Implement this test case if needed
  });
});
