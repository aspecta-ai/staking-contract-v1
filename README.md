# Aspecta Staking Contract V1

# Introduction

This contract implements the Aspecta staking contract. Users can stake on their champion devs or projects and earn rewards based on their Build Index. Devs and projects also earn rewards for being staked and maintaining good Build Index.

# Setup Environment

1. Install Rust

```
curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh
```

2. Install Forge (This may take a long time, 30 minutes to 1 hour)

```
cargo install --git https://github.com/foundry-rs/foundry forge --bins --locked
```

3. Install the **LATEST** Node.js **LTS**

```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc  # or ~/.zshrc
nvm ls-remote  # list all available versions
nvm install xxxxxx  # e.g. nvm install v20.14.0
```

4. Install Node.js Modules

```
npm install
```

5. Create `.env` file and configure environment variables, e.g. `.env.template`

# Run Unit Tests

```
npm run test
```

# Deploy Contract

```
npm run deploy
```

# Verify Contract

```
npx hardhat verify --network mainnet PROXY_ADDRESS
```

# Upgrade Contract

**You need to modify the existing contract, instead of creating a new contract.**

1. Upgrade the AspectaBuildingPoint contract

```
npm run upgrade-bp
```

2. Upgrade the AspectaDevPool contract

```
npm run upgrade-bc
```

3. Upgrade the AspectaDevPoolFactory contract

```
npm run upgrade-pf
```

4. Upgrade the PoolFactoryGetters contract

```
npm run upgrade-fg
```
