import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    hardhat: {
      chainId: 31337,
    },
    goerli: {
      chainId: 5,
      url: "https://goerli.infura.io/v3/309820d3955640ec9cda472d998479ef",
      accounts:
        process.env.DEPLOYER_PRIVATEKEY !== undefined
          ? [process.env.DEPLOYER_PRIVATEKEY]
          : [],
    },
  },
};

export default config;
