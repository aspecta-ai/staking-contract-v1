import {
    GetSecretValueCommand,
    SecretsManagerClient,
} from '@aws-sdk/client-secrets-manager';

export async function getSecretValue(secretName: string, region: string) {
    const client = new SecretsManagerClient({
        region: region,
    });

    let response;

    try {
        response = await client.send(
            new GetSecretValueCommand({
                SecretId: secretName,
                VersionStage: 'AWSCURRENT', // VersionStage defaults to AWSCURRENT if unspecified
            }),
        );
    } catch (error) {
        // For a list of exceptions thrown, see
        // https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        throw error;
    }

    if (!response.SecretString) {
        throw new Error('SecretString not found');
    }

    return JSON.parse(response.SecretString)['1'];
}
