import '@nomicfoundation/hardhat-foundry';
import '@nomicfoundation/hardhat-toolbox';
import '@openzeppelin/hardhat-upgrades';
import 'dotenv/config';
import { HardhatUserConfig } from 'hardhat/config';

import { privateKey } from './private-key';

const config: HardhatUserConfig = {
    solidity: '0.8.25',
    networks: {
        mainnet: {
            url: process.env.JSON_RPC_URL,
            accounts: [privateKey],
        },
    },
};

export default config;
