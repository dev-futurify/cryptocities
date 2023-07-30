import { expect } from "chai";
import { ethers } from "hardhat";

describe("SteadyCoin", function () {
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

describe("SteadyEngine", function () {
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

describe("SteadyMarketplace", function () {
  let steadyMarketplace;
  let owner;
  let addr1;
  let addr2;
  let tokenContract;
  let nftId;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy the SteadyMarketplace contract
    const SteadyMarketplaceFactory = await ethers.getContractFactory(
      "SteadyMarketplace"
    );
    steadyMarketplace = await SteadyMarketplaceFactory.deploy();
    await steadyMarketplace.deployed();

    // Deploy the ERC1155 token contract for testing
    const ERC1155Factory = await ethers.getContractFactory("ERC1155Mock");
    tokenContract = await ERC1155Factory.deploy();
    await tokenContract.deployed();

    // Mint some initial tokens for testing
    nftId = 1;
    await tokenContract.mint(owner.address, nftId, 100, []);

    // Approve SteadyMarketplace contract to transfer tokens
    await tokenContract.setApprovalForAll(steadyMarketplace.address, true);
  });

  it("Should create a sell order", async function () {
    const unitPrice = ethers.utils.parseEther("1");
    const noOfTokensForSale = 10;

    await steadyMarketplace.createSellOrder(
      nftId,
      tokenContract.address,
      unitPrice,
      noOfTokensForSale
    );

    const sellOrders = await steadyMarketplace.getOrders(
      nftId,
      tokenContract.address
    );
    expect(sellOrders.length).to.equal(1);
    expect(sellOrders[0].owner).to.equal(owner.address);
    expect(sellOrders[0].quantity).to.equal(noOfTokensForSale);
    expect(sellOrders[0].unitPrice).to.equal(unitPrice);
  });

  it("Should not create a sell order with invalid unit price", async function () {
    await expect(
      steadyMarketplace.createSellOrder(nftId, tokenContract.address, 0, 10)
    ).to.be.revertedWith("SteadyMarketplace: Price must be greater than 0.");
  });

  it("Should not create a sell order without sufficient balance", async function () {
    const unitPrice = ethers.utils.parseEther("1");
    const noOfTokensForSale = 101;

    await expect(
      steadyMarketplace.createSellOrder(
        nftId,
        tokenContract.address,
        unitPrice,
        noOfTokensForSale
      )
    ).to.be.revertedWith("SteadyMarketplace: Insufficient token balance.");
  });

  it("Should cancel a sell order", async function () {
    const unitPrice = ethers.utils.parseEther("1");
    const noOfTokensForSale = 10;

    await steadyMarketplace.createSellOrder(
      nftId,
      tokenContract.address,
      unitPrice,
      noOfTokensForSale
    );

    await steadyMarketplace.cancelSellOrder(nftId, tokenContract.address);

    const sellOrders = await steadyMarketplace.getOrders(
      nftId,
      tokenContract.address
    );
    expect(sellOrders.length).to.equal(0);
  });

  it("Should create a buy order", async function () {
    const unitPrice = ethers.utils.parseEther("1");
    const noOfTokensForSale = 10;
    const noOfTokensToBuy = 5;

    await steadyMarketplace.createSellOrder(
      nftId,
      tokenContract.address,
      unitPrice,
      noOfTokensForSale
    );

    const initialOwnerBalance = await tokenContract.balanceOf(
      owner.address,
      nftId
    );
    const initialBuyerBalance = await tokenContract.balanceOf(
      addr1.address,
      nftId
    );

    await steadyMarketplace
      .connect(addr1)
      .createBuyOrder(
        nftId,
        tokenContract.address,
        noOfTokensToBuy,
        owner.address,
        { value: unitPrice.mul(noOfTokensToBuy) }
      );

    const finalOwnerBalance = await tokenContract.balanceOf(
      owner.address,
      nftId
    );
    const finalBuyerBalance = await tokenContract.balanceOf(
      addr1.address,
      nftId
    );

    expect(finalOwnerBalance.sub(initialOwnerBalance)).to.equal(
      noOfTokensToBuy
    );
    expect(initialBuyerBalance.sub(finalBuyerBalance)).to.equal(
      noOfTokensToBuy
    );
  });

  it("Should not create a buy order with insufficient funds", async function () {
    const unitPrice = ethers.utils.parseEther("1");
    const noOfTokensForSale = 10;
    const noOfTokensToBuy = 5;

    await steadyMarketplace.createSellOrder(
      nftId,
      tokenContract.address,
      unitPrice,
      noOfTokensForSale
    );

    await expect(
      steadyMarketplace
        .connect(addr1)
        .createBuyOrder(
          nftId,
          tokenContract.address,
          noOfTokensToBuy,
          owner.address,
          { value: unitPrice.mul(noOfTokensToBuy).sub(1) }
        )
    ).to.be.revertedWith(
      "SteadyMarketplace: Less ETH provided for the purchase."
    );
  });
});
