import 'dotenv/config';
import { ethers } from 'hardhat';

import { getSecretValue } from '../utils';

async function main() {
    const awsRegion = process.env.AWS_REGION;
    const secretName = process.env.AWS_SECRET_NAME;
    const jsonRPCURL = process.env.JSON_RPC_URL;

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
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
