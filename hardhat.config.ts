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
        // Run `npx hardhat node` will start a local network for development.
        localhost: {
            url: 'http://127.0.0.1:8545',
            // WARNING: These accounts, and their private keys, are publicly known.
            // Any funds sent to them on Mainnet or any other live network WILL BE LOST.
            accounts: [
                '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
            ],
        },
    },
};

export default config;
