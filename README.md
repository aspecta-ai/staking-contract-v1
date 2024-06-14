# contract-v1-core

# Setup Environment

1. Install Rust

```
curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh
```

2. Install Forge (This may take a long time, 30 minutes to 1 hour)

```
cargo install --git https://github.com/foundry-rs/foundry forge --bins --locked
```

3. Install Node.js **LTS**

```
curl -sL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs npm
```

4. Install Node.js Modules

```
npm install
```

5. Create `.env` file and configure environment variables, e.g. `.env.template`

# Run Unit Tests

```
forge test
```

# Deploy Contract

```
npm run deploy
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
