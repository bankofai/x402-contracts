import { HardhatUserConfig } from '@sun-protocol/sunhat';
import '@nomicfoundation/hardhat-toolbox';
import '@nomiclabs/hardhat-vyper';
import '@sun-protocol/sunhat';
import '@nomicfoundation/hardhat-foundry';

import * as dotenv from 'dotenv';
dotenv.config();

const settings = {
  optimizer: {
    enabled: true, // enabled for optimizer
    runs: 999999, // runs time for optimizer run
  },
};

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      { version: '0.8.25', settings }, // current solc version 1
    ],
  },
  vyper: {
    compilers: [
      { version: '0.2.8' }, // current vyper compilers version 1
    ],
  },
  // settings for different networks
  networks: {
    tron: {
      url: process.env.TRON_RPC_URL || 'https://nile.trongrid.io/jsonrpc', // tron rpc url
      tron: true, // enable tron network
      deploy: ['deploy/'], // folder for tron deploy scripts
      accounts: process.env.PRIVATE_KEY ? [ process.env.PRIVATE_KEY ] : [], // account private key for deploy
    },
  },
  tronSolc: {
    enable: true, // enable tron solc compiler
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
    },
  },
  llm: {
    defaultProvider: 'openai',
    // promptTemplate:
    //   'As a world-class smart contract auditor, please perform a detailed security review of the following {language} code from the file "{contractName}". Focus especially on re-entrancy, integer overflows, and access control issues.',
    providers: {
      openai: {
        apiKey: process.env.OPENAI_API_KEY || '',
        model: process.env.MODEL_NAME || 'gpt-4o',
      },
      // azure_openai: {
      //   apiKey: process.env.OPENAI_API_KEY || '',
      //   endpoint: process.env.OPENAI_ENDPOINT || '',
      //   deploymentName: process.env.OPENAI_DEPLOYMENT || '',
      //   apiVersion: process.env.OPENAI_API_VERSION || '',
      //   model: process.env.MODEL_NAME || 'gpt-4o',
      // },
      // gemini: {
      //   apiKey: process.env.GEMINI_API_KEY || '',
      //   model: process.env.MODEL_NAME || 'gemini-2.5-pro',
      // },
      // qwen: {
      //   apiKey: process.env.QWEN_API_KEY || '',
      //   model: process.env.MODEL_NAME || 'qwen-turbo',
      //   baseURL: process.env.QWEN_BASE_URL || '',
      // },
      // deepseek: {
      //   apiKey: process.env.DEEPSEEK_API_KEY || '',
      //   model: process.env.MODEL_NAME || 'deepseek-coder',
      //   baseURL: process.env.DEEPSEEK_BASE_URL || '',
      // },
    },
  },
};

export default config;
