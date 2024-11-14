The following instructions explain how to manually deploy the Example from scratch including EigenLayer and BitDSM specific contracts using Foundry (forge) to a local anvil chain, and start Typescript Operator application and tasks.

## Development Environment

This section describes the tooling required for local development.

### 1. Non-Nix Environment

Install dependencies:

- [Node](https://nodejs.org/en/download/)
- [Typescript](https://www.typescriptlang.org/download)
- [ts-node](https://www.npmjs.com/package/ts-node)
- [tcs](https://www.npmjs.com/package/tcs#installation)
- [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)
- [Foundry](https://getfoundry.sh/)
- [ethers](https://www.npmjs.com/package/ethers)

### 2. Deploy Eigenlayer Contracts

First, clone the hello-world-avs repository:

```bash
git clone git@github.com:Layr-Labs/hello-world-avs.git
cd hello-world-avs
```

### 3. Start Anvil Chain on new terminal

In terminal window #1, execute the following commands:

```bash
# Install npm packages
npm install

# Start local anvil chain
npm run start:anvil
```

In a separate terminal window, execute the following commands:

```sh
# Setup .env file
cp .env.example .env

cp contracts/.env.example contracts/.env

cd contracts/anvil
```

then run the below command

```sh
cd contracts
forge build
```

then cd to anvil directory

```sh
cd anvil
```

and run the below command

```sh
./deploy-el.sh

```

this will deploy the EigenLayer contracts.

then copy proxyAdmin, delegation, and avsDirectory addresses from contracts/deployments/core/31337.json file and update the eigenlayer_addresses.json file with these addresses.
Note: leave the rewardsCoordinator address same as the one in the eigenlayer_addresses.json file.
