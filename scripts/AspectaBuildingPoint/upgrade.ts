import 'dotenv/config';
import { ethers, upgrades } from 'hardhat';
import hre from 'hardhat';

async function main() {
    const jsonRPCURL = process.env.JSON_RPC_URL;
    const aspectaBuildingPointAddress =
        process.env.ASPECTA_BUILDING_POINT_ADDRESS;

    // Check if the required environment variables are set
    if (!jsonRPCURL) {
        throw new Error('JSON_RPC_URL is not set');
    }
    if (!aspectaBuildingPointAddress) {
        throw new Error('ASPECTA_BUILDING_POINT_ADDRESS is not set');
    }

    // Create a provider instance
    const provider = hre.ethers.provider;

    // Create a signer instance
    const signer = await hre.ethers.provider.getSigner();

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
    const aspectaBuildingPoint = await upgrades.upgradeProxy(
        aspectaBuildingPointAddress,
        AspectaBuildingPoint,
    );
    await aspectaBuildingPoint.waitForDeployment();
    console.log('AspectaBuildingPoint upgraded');
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
