const fs = require('fs');
const {
    GetSecretValueCommand,
    SecretsManagerClient,
} = require('@aws-sdk/client-secrets-manager');
require('dotenv').config();

async function getPrivateKey() {
    const client = new SecretsManagerClient({
        region: process.env.AWS_REGION,
    });
    const res = await client.send(
        new GetSecretValueCommand({
            SecretId: process.env.AWS_SECRET_NAME,
            VersionStage: 'AWSCURRENT', // VersionStage defaults to AWSCURRENT if unspecified
        }),
    );
    return JSON.parse(res.SecretString)['1'];
}

getPrivateKey().then((privateKey) => {
    fs.writeFileSync(
        'private-key.ts',
        `const privateKey = "${privateKey}";\n\nexport { privateKey };`,
    );
});
