import { ethers } from "hardhat";

async function main() {
  const steadyCoin = await ethers.deployContract("SteadyCoin");
  await steadyCoin.waitForDeployment();

  console.log(`SteadyCoin deployed to ${steadyCoin.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
