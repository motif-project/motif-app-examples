The following instructions explain how to manually deploy the Example from scratch including EigenLayer and BitDSM specific contracts using Foundry (forge) to a local anvil chain, and start Typescript Operator application and tasks.

# Local Deployment Guide

This guide explains how to deploy the Example project locally using Foundry (forge), including EigenLayer and BitDSM contracts. It also covers setting up the Typescript Operator application and tasks.

## Prerequisites

### Required Tools

- [Node.js](https://nodejs.org/en/download/)
- [Typescript](https://www.typescriptlang.org/download)
- [ts-node](https://www.npmjs.com/package/ts-node)
- [tcs](https://www.npmjs.com/package/tcs#installation)
- [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)
- [Foundry](https://getfoundry.sh/)
- [ethers](https://www.npmjs.com/package/ethers)

## Deployment Steps

### 1. Initial Setup

```bash
# Clone the repository
git clone git@github.com:Layr-Labs/hello-world-avs.git
cd hello-world-avs

# Install dependencies
npm install
```

### 2. Start Local Anvil Chain

In a new terminal window:

```bash
npm run start:anvil
```

and note down the private key for updating your .env files

### 3. Deploy EigenLayer Contracts

now go back to your original terminal and run the following commands

```bash
# Set up environment files
cp .env.example .env
cp contracts/.env.example contracts/.env

# Build and deploy contracts
cd contracts
forge build
cd anvil
./deploy-el.sh
```

### 4. Configure BitDSM Setup

```bash
# Clone BitDSM repository (if not already done)
git clone git@github.com:BitDSM/BitDSM-examples.git
cd BitDSM-examples

# Set up environment files
cp .env.example .env
cp script/anvil-testnet/operator/.env.example script/anvil-testnet/operator/.env
```

and update the .env file with the private key copied from anvil terminal. as anvil gives 10 accounts with different private keys. you can use any of them in your .env files and update the btc_public_key with the corresponding public key for that private key of bitcoin network

Important:

1. Copy the following addresses from `contracts/deployments/core/31337.json` located in the hello-world-avs contracts directory:
   - proxyAdmin
   - delegation
   - avsDirectory
2. Update these addresses in `script/anvil-testnet/eigenlayer_addresses.json` in anvil testnet object located in the last object of the file
   - Keep the existing rewardsCoordinator address
   - Use the delegation address for the delegationManager field

it looks like this

```sh
 "anvil": {
    "proxyAdmin": "..",
    "delegationManager": ......
```

3. Update your private key in the `.env` file of BitDSM examples repository

### 5. Deploy BitDSM Contracts

first source the .env file to get the private key for updating the .env files

```bash
source .env
```

```bash
# Build contracts
forge build

# Deploy BitDSM contracts
forge script script/anvil-testnet/DeployBitDSM.s.sol:DeployBitDSM --sig "run(string,string)" "anvil" " " --rpc-url http://localhost:8545 --broadcast
```

Now to deploy the cdp contract

```bash
# Deploy CDP
forge script script/cdp/Cdp.s.sol:DeployCDP --rpc-url http://localhost:8545 --broadcast --private-key $PRIVATE_KEY
```

and then register the application, run the following command

```bash
# Register Application
forge script script/cdp/RegisterApp.s.sol:RegisterApp --rpc-url http://localhost:8545 --broadcast --private-key $PRIVATE_KEY
```

then run the CdpController.s.sol to interact with the cdp contract.
for interacting with the Cdp app, user need to first delegate the app from bitcoin pod manager. then run the following command to open cdp

to register the operator, run the following command

```bash
cd script/anvil-testnet/operator
npm install
source .env
npm run start:operator
```

to create a pod, run the following command
Note : This is just to develop locally, in production, pod will be created but need to deposit the funds to the pod. then the operator will confirm the deposit.
Remember to update the .env file for different CLIENT_PRIVATE_KEY for each new BitcoinPod

```bash
npm run start:Pod

```

to delegate the app to the pod, run the following command

```bash
forge script script/cdp/CdpController.s.sol:DelegateCdpApp --rpc-url http://localhost:8545 --broadcast --private-key $CLIENT_PRIVATE_KEY
```

to open the cdp, run the following command

```bash
forge script script/cdp/CdpController.s.sol:CdpControllerScript --rpc-url http://localhost:8545 --broadcast --private-key $CLIENT_PRIVATE_KEY
```

## Important Notes

- Ensure all services are running before proceeding with subsequent steps
- Keep track of deployed contract addresses
- Verify all prerequisites are installed and configured correctly
- The CDP operations require prior delegation from the bitcoin pod manager

```

```
