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
