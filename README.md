# MOTIF Example Applications Repository

This repository contains example applications built on top of the Motif protocol for Ethereum.

## **CDP (Collateralized Debt Position) Contract**

This example showcases the implementation of a simple CDP (Collateralized Debt Position) contract utilizing the Motif protocol. The guide focuses on deployment and development on the Holesky testnet with a fully functional Operator node.

For local deployment and development, please refer to: [Local Deployment](https://github.com/motif-project/motif-app-examples/tree/80c58b73cb1675560ebe4547c09f2bdc512f4efc/script/anvil-testnet)

## Setup

Follow the [Foundary Installation Guide](https://book.getfoundry.sh/getting-started/installation) to install the necessary dependencies:

Once insatalled, run the following command for compiling the contracts.   

```bash
forge build
```

### **1. Deploy Oracle**

The oracle system supports two types of price feeds:
- Chainlink Price Feeds
- Custom Price Feeds

#### **Deploy Oracle Registry**

First, deploy the Oracle Registry contract which manages all price feed registrations.
To Create a New Oracle refer to the below solidity code snippet:

```solidity
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        Oracle oracle = new Oracle();
```
---

### **2. Deploy CDP**

Once the Oracle is deployed, you can deploy the CDP contract by referring to the below solidity code snippet:

**Parameters:**
- `_BITCOIN_POD_MANAGER`: The address of the Bitcoin Pod we want to register with.
- `OracleAddress`: The address of the Oracle we deployed on last step.

```solidity
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        CDP cdp = new CDP(_BITCOIN_POD_MANAGER, _ORACLE);
```

---

### 3. Register App

To register your application, you'll need to call the `registerApp` function with your app's address

**Parameters:**
- `appAddress`: The contract address of your application

To register your app, you need the address to `AppRegistry` contractand your Apps (in this case CDP) contract address

Then Create a random salt and expiry

```solidity
    bytes32 salt = bytes32(uint256(1));
uint256 expiry = block.timestamp + 1 days;
```

 Calculate the digest hash of the app registration by calling the `calculateAppRegistrationDigestHash` function from the `AppRegistry` contract. 
 
 Sign the digest hash and the broadcast the transaction.

```solidity vm.startBroadcast(deployerPrivateKey);

        try
            AppRegistry(_APP_REGISTRY).calculateAppRegistrationDigestHash(
                _APP_ADDRESS,
                _APP_REGISTRY,
                salt,
                expiry
            )
        returns (bytes32 digestHash) {
            console.log("Digest Hash:", vm.toString(digestHash));

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(
                deployerPrivateKey,
                digestHash
            );
            bytes memory signature = abi.encodePacked(r, s, v);
            AppRegistry(_APP_REGISTRY).registerApp(
                _APP_ADDRESS,
                signature,
                salt,
                expiry
            );
```

---

### 4. Update App Metadata

Once the app is registered, you can update the app's metadata URI by calling the `updateAppMetadataURI` function from the `AppRegistry` contract. It is recommended as the Metadata is displayed on the BitDSM UI.

First you need upload the metadata.json file to IPFS and get the URI. 

Metadata JSON file example:
```json
{"name": " ",
  "website": " ",
  "description": " "
}
```

then you can update the metadata URI by calling the `updateAppMetadataURI` function from the `AppRegistry` contract.

```solidity
    app = CDP(_APP_ADDRESS);
        app.updateAppMetadataURI(
            "https://your_json_uri.json",
            _APP_REGISTRY
        );
```

---

### 5. Deregister App

To deregister your app, you need to call the `deregisterApp` function from the `AppRegistry` contract.

**Parameters:**
- `appAddress`: The contract address of your application
- `AppRegistry`: The address of the `AppRegistry` contract

```solidity
    AppRegistry(_APP_REGISTRY).deregisterApp(_APP_ADDRESS);
```
