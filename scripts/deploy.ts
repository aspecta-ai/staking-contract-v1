import 'dotenv/config';
import { ethers, upgrades } from 'hardhat';

import { getSecretValue } from './utils';

async function main() {
    const awsRegion = process.env.AWS_REGION;
    const secretName = process.env.AWS_SECRET_NAME;
    const jsonRPCURL = process.env.JSON_RPC_URL;

    const defaultInflationRate = process.env.DEFAULT_INFLATION_RATE;
    const defaultShareDecayRate = process.env.DEFAULT_SHARE_DECAY_RATE;
    const defaultRewardCut = process.env.DEFAULT_REWARD_CUT;
    const defaultLockPeriod = process.env.DEFAULT_LOCK_PERIOD;

    // Check if the required environment variables are set
    if (!awsRegion) {
        throw new Error('AWS_REGION is not set');
    }
    if (!secretName) {
        throw new Error('AWS_SECRET_NAME is not set');
    }
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

    // Read the private key from AWS Secrets Manager
    const privateKey = await getSecretValue(
        secretName as string,
        awsRegion as string,
    );

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
        signer,
    );
    const aspectaBuildingPoint = await AspectaBuildingPoint.deploy(
        await signer.getAddress(),
    );
    await aspectaBuildingPoint.waitForDeployment();
    console.log(
        'AspectaBuildingPoint deployed to:',
        await aspectaBuildingPoint.getAddress(),
    );

    const AspectaDevPool = await ethers.getContractFactory(
        'AspectaDevPool',
        signer,
    );

    const aspectaDevPool = await AspectaDevPool.deploy();
    await aspectaDevPool.waitForDeployment();
    console.log(
        'AspectaDevPool deployed to:',
        await aspectaDevPool.getAddress(),
    );

    const AspectaDevPoolFactory = await ethers.getContractFactory(
        'AspectaDevPoolFactory',
        signer,
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
