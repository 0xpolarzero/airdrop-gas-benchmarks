import '@nomicfoundation/hardhat-toolbox-viem';
import '@nomicfoundation/hardhat-viem';
import '@nomicfoundation/hardhat-foundry';
import '@nomicfoundation/hardhat-ethers';
import 'hardhat-gas-reporter';
import '@typechain/hardhat';
import 'dotenv/config';
import { HardhatUserConfig } from 'hardhat/config';

const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || 'api-key';

/** @type import('hardhat/config').HardhatUserConfig */
const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.20',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: '0.4.25',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
    outputFile: 'gas-report.txt',
    noColors: true,
    coinmarketcap: COINMARKETCAP_API_KEY,
  },
  typechain: {
    outDir: 'typechain',
    target: 'ethers-v6',
  },
  mocha: {
    timeout: 200000,
  },
};

export default config;
