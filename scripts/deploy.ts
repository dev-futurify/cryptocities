import { ethers } from "hardhat";

async function main() {
  const steadyCoin = await ethers.deployContract("SteadyCoin");
  await steadyCoin.waitForDeployment();

  console.log(`SteadyCoin deployed to ${steadyCoin.address}`);

  const steadyMarketplace = await ethers.deployContract("SteadyMarketplace");

  console.log(`SteadyMarketplace deployed to ${steadyMarketplace.address}`);

  const steadyEngine = await ethers.deployContract("SteadyEngine", [
    steadyCoin.address,
    steadyMarketplace.address,
  ]);

  console.log(`SteadyEngine deployed to ${steadyEngine.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
