import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

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
    mumbai: {
      url: process.env.MUMBAI_RPC_URL,
      accounts: [process.env.TEST_WALLET_PRIVATE_KEY || ""],
    },
    mainnet: {
      chainId: 137,
      url: process.env.POLYGON_RPC_URL,
      accounts: [process.env.WALLET_PRIVATE_KEY || ""],
    },
  },
  etherscan: {
    apiKey: process.env.POLYGONSCAN_KEY,
  },
};

export default config;
