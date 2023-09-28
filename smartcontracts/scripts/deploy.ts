import { ethers } from "hardhat";

async function main() {
  console.log("Initializing deployment...");

  const steadyCoin = await ethers.deployContract("SteadyCoin");
  console.log(`SteadyCoin deployed to ${steadyCoin.address}`);

  const steadyFormula = await ethers.deployContract("SteadyFormula");
  console.log(`SteadyFormula deployed to ${steadyFormula.address}`);

  const steadyMarketplace = await ethers.deployContract("SteadyMarketplace", [
    steadyFormula.address,
  ]);
  console.log(`SteadyMarketplace deployed to ${steadyMarketplace.address}`);

  const steadyEngine = await ethers.deployContract("SteadyEngine", [
    steadyCoin.address,
    steadyMarketplace.address,
    steadyFormula.address,
  ]);
  console.log(`SteadyEngine deployed to ${steadyEngine.address}`);

  console.log("Deployment completed!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
