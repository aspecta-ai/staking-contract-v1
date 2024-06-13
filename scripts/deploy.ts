import 'dotenv/config';
import { ethers, upgrades } from 'hardhat';

import { privateKey } from '../private-key';

async function main() {
    const jsonRPCURL = process.env.JSON_RPC_URL;

    const defaultInflationRate = process.env.DEFAULT_INFLATION_RATE;
    const defaultShareDecayRate = process.env.DEFAULT_SHARE_DECAY_RATE;
    const defaultRewardCut = process.env.DEFAULT_REWARD_CUT;
    const defaultLockPeriod = process.env.DEFAULT_LOCK_PERIOD;

    // Check if the required environment variables are set
    if (!jsonRPCURL) {
        throw new Error('JSON_RPC_URL is not set');
    }

    if (!defaultInflationRate) {
        throw new Error('DEFAULT_INFLATION_RATE is not set');
    }
    if (!defaultShareDecayRate) {
        throw new Error('DEFAULT_SHARE_DECAY_RATE is not set');
    }
    if (!defaultRewardCut) {
        throw new Error('DEFAULT_REWARD_CUT is not set');
    }
    if (!defaultLockPeriod) {
        throw new Error('DEFAULT_LOCK_PERIOD is not set');
    }

    // Create a provider instance
    const provider = new ethers.JsonRpcProvider(jsonRPCURL as string);

    // Create a signer instance
    const signer = new ethers.Wallet(privateKey, provider);

    let network = await provider.getNetwork();
    console.log('Network:', network['name']);
    console.log('Chain ID:', network['chainId']);
    console.log('Account:', await signer.getAddress());
    console.log(
        'Balance:',
        ethers.formatEther(
            await provider.getBalance(await signer.getAddress()),
        ),
        'ether',
    );

    const AspectaBuildingPoint = await ethers.getContractFactory(
        'AspectaBuildingPoint',
    );
    const aspectaBuildingPoint = await upgrades.deployProxy(
        AspectaBuildingPoint,
        [await signer.getAddress()],
    );
    await aspectaBuildingPoint.waitForDeployment();
    console.log(
        'AspectaBuildingPoint deployed to:',
        await aspectaBuildingPoint.getAddress(),
    );

    const AspectaDevPool = await ethers.getContractFactory('AspectaDevPool');
    const aspectaDevPool = await AspectaDevPool.deploy();
    await aspectaDevPool.waitForDeployment();
    console.log(
        'AspectaDevPool deployed to:',
        await aspectaDevPool.getAddress(),
    );

    const AspectaDevPoolFactory = await ethers.getContractFactory(
        'AspectaDevPoolFactory',
    );
    const aspectaDevPoolFactory = await upgrades.deployProxy(
        AspectaDevPoolFactory,
        [
            await signer.getAddress(),
            await aspectaBuildingPoint.getAddress(),
            await aspectaDevPool.getAddress(),
            defaultInflationRate,
            defaultShareDecayRate,
            defaultRewardCut,
            defaultLockPeriod,
        ],
    );
    await aspectaDevPoolFactory.waitForDeployment();
    console.log(
        'aspectaDevPoolFactory deployed to:',
        await aspectaDevPoolFactory.getAddress(),
    );
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
