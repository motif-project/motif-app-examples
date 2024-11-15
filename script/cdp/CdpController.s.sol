// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {CDP} from "../../src/cdp/Cdp.sol";
import {Oracle} from "../../src/cdp/Oracle.sol";
import {console} from "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";
import "../../src/cdp/Oracle.sol";
import {IBitcoinPodManager} from "@bitdsm/interfaces/IBitcoinPodManager.sol";
import {BitDSMServiceManager} from "@bitdsm/core/BitDSMServiceManager.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// forge script script/cdp/CdpController.s.sol:DelegateCdpApp --rpc-url http://localhost:8545 --broadcast --private-key $CLIENT_PRIVATE_KEY
contract DelegateCdpApp is Script {
    address internal _BITCOIN_POD_MANAGER;
    address internal _APP_ADDRESS;

    function setUp() public {
        // _BITCOIN_POD_MANAGER = 0x99bbA657f2BbC93c02D617f8bA121cB8Fc104Acf;
        string memory bitdsmRoot = vm.readFile(
            "script/anvil-testnet/bitdsm_addresses.json"
        );
        _BITCOIN_POD_MANAGER = stdJson.readAddress(
            bitdsmRoot,
            "$.BitcoinPodManagerProxy"
        );
        string memory cdpRoot = vm.readFile(
            "script/anvil-testnet/cdp-addresses.json"
        );

        _APP_ADDRESS = stdJson.readAddress(cdpRoot, "$.cdp");

        // _APP_ADDRESS = 0x0a52519F97941C942752eE44156A6EdeCA156Cdd;
    }

    function run() external {
        uint256 clientPrivateKey = vm.envUint("CLIENT_PRIVATE_KEY");
        vm.startBroadcast(clientPrivateKey);

        IBitcoinPodManager bitcoinPodManager = IBitcoinPodManager(
            _BITCOIN_POD_MANAGER
        );
        address bitcoinPod = bitcoinPodManager.getUserPod(
            vm.addr(clientPrivateKey)
        );
        // Delegate the app using the pod
        bitcoinPodManager.delegatePod(bitcoinPod, _APP_ADDRESS);
        console.log("bitcoinPod", bitcoinPod);
        console.log("app delegated to", _APP_ADDRESS);
        vm.stopBroadcast();
    }
}

// to deploy on local
// forge script script/cdp/CdpController.s.sol:CdpControllerScript --rpc-url http://localhost:8545 --broadcast --private-key $CLIENT_PRIVATE_KEY

// to deploy on holesky
// forge script script/cdp/CdpController.s.sol:CdpControllerScript --fork-url https://1rpc.io/holesky --broadcast --private-key $DEPLOYER_PRIVATE_KEY
contract CdpControllerScript is Script {
    address internal _BITCOIN_POD_MANAGER;
    address internal _APP_ADDRESS;

    function setUp() public {
        // to get addresses from json files
        string memory bitdsmRoot = vm.readFile(
            "script/anvil-testnet/bitdsm_addresses.json"
        );
        string memory cdpRoot = vm.readFile(
            "script/anvil-testnet/cdp-addresses.json"
        );

        _BITCOIN_POD_MANAGER = stdJson.readAddress(
            bitdsmRoot,
            "$.BitcoinPodManagerProxy"
        );
        _APP_ADDRESS = stdJson.readAddress(cdpRoot, "$.cdp");

        // // for hardcoded addresses
        // _BITCOIN_POD_MANAGER = 0x99bbA657f2BbC93c02D617f8bA121cB8Fc104Acf; // replace with actual address
        // _APP_ADDRESS = 0x36C02dA8a0983159322a80FFE9F24b1acfF8B570; // replace with actual address
    }

    function run() external {
        // this the private key of the bitcoin pod owner who delegrated the app
        uint256 deployerPrivateKey = vm.envUint("CLIENT_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        CDP cdp = CDP(_APP_ADDRESS);
        uint256 debtAmount = 500; // 5000 usd
        // Open CDP using the pod as collateral
        cdp.openCDP(debtAmount);

        // Generate more debt
        cdp.generateDebt(debtAmount);

        // Get CDP details
        (uint256 collateral, uint256 debt, uint256 lastUpdate) = cdp.getCDP(
            vm.addr(deployerPrivateKey)
        );
        console.log("Collateral amount:", collateral);
        console.log("Debt amount:", debt);
        console.log("Last interest update:", lastUpdate);

        // Get collateral ratio
        uint256 ratio = cdp.getCollateralRatio(vm.addr(deployerPrivateKey));
        console.log("Collateral ratio:", ratio);

        vm.stopBroadcast();
    }
}

// forge script script/cdp/CdpController.s.sol:BitDSMServiceManagerScript --rpc-url http://localhost:8545 --broadcast --private-key $DEVELOPER_PRIVATE_KEY
contract BitDSMServiceManagerScript is Script {
    address internal _BITCOIN_POD_MANAGER;
    address internal _SERVICE_MANAGER;
    address internal _POD_ADDRESS;

    function setUp() public {
        _BITCOIN_POD_MANAGER = 0x99bbA657f2BbC93c02D617f8bA121cB8Fc104Acf;
        _SERVICE_MANAGER = 0x0E801D84Fa97b50751Dbf25036d067dCf18858bF; // Replace with actual service manager address
        _POD_ADDRESS = 0x3E69aeCb6a5abAc2D87d6707649E2fB0173ee2Da; // Replace with actual pod address
    }

    function run() external {
        uint256 operatorPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(operatorPrivateKey);
        BitDSMServiceManager serviceManager = BitDSMServiceManager(
            _SERVICE_MANAGER
        );
        IBitcoinPodManager podManager = IBitcoinPodManager(
            _BITCOIN_POD_MANAGER
        );

        IBitcoinPodManager.BitcoinDepositRequest memory request = podManager
            .getBitcoinDepositRequest(_POD_ADDRESS);

        console.log("Request Amount:", request.amount);
        //console.log("Transaction ID:", request.transactionId);
        console.log("Is Pending:", request.isPending); // Create signature for deposit confirmation
        // bytes32 messageHash = keccak256(
        //     abi.encodePacked(
        //         _POD_ADDRESS,
        //         vm.addr(operatorPrivateKey),
        //         request.amount, // Use amount from the struct
        //         request.transactionId, // Use txId from the struct
        //         request.isPending // Use isPending from the struct
        //     )
        // );
        // bytes32 ethSignedMessageHash = keccak256(
        //     abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        // );

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                _POD_ADDRESS,
                vm.addr(operatorPrivateKey),
                request.amount,
                request.transactionId,
                true
            )
        );
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(
            messageHash
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            operatorPrivateKey,
            ethSignedMessageHash
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        // Call confirmDeposit on service manager
        BitDSMServiceManager(_SERVICE_MANAGER).confirmDeposit(
            _POD_ADDRESS,
            signature
        );

        vm.stopBroadcast();
    }
}
