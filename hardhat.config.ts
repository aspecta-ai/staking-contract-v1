import '@nomicfoundation/hardhat-foundry';
import '@nomicfoundation/hardhat-toolbox';
import '@openzeppelin/hardhat-upgrades';
import 'dotenv/config';
import { HardhatUserConfig } from 'hardhat/config';

const config: HardhatUserConfig = {
    solidity: '0.8.25',
    networks: {
        mainnet: {
            url: process.env.JSON_RPC_URL,
        },
    },
};

export default config;
