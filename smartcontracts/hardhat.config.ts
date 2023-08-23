import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

// @url: quicknode HTTP provider url
// @accounts: DO NOT USE SAME ACCOUNT FOR TESTING AND MAINET DEPLOYER
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    zkEVM_testnet: {
      url: process.env.ZKEVM_TESTNET_RPC_URL,
      accounts: [process.env.TEST_WALLET_PRIVATE_KEY || ""],
    },
    zkEVM_mainnet: {
      chainId: 1101,
      url: process.env.ZKEVM_MAINNET_RPC_URL,
      accounts: [process.env.WALLET_PRIVATE_KEY || ""],
    },
  },
  etherscan: {
    apiKey: process.env.ZKEVM_POLYGONSCAN_KEY,
  },
};

export default config;
