import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-foundry';
import 'hardhat-gas-reporter';
import 'dotenv/config';
import { HardhatUserConfig } from 'hardhat/config';

const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || 'api-key';

/** @type import('hardhat/config').HardhatUserConfig */
const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.20',
      },
      {
        version: '0.4.25',
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
  mocha: {
    timeout: 200000,
  },
};

export default config;
