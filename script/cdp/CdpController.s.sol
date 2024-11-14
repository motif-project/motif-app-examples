// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {CDP} from "../../src/cdp/Cdp.sol";
import {Oracle} from "../../src/cdp/Oracle.sol";
import {console} from "forge-std/console.sol";
import "../../src/cdp/mocks/MockBitcoinPodManager.sol";
import "../../src/cdp/mocks/MockBitcoinPod.sol";
import "../../src/cdp/mocks/MockAppRegistry.sol";
import "../../src/cdp/Oracle.sol";

// forge script script/cdp/CdpController.s.sol:MockBitcoinPodManagerScript --fork-url http://localhost:8545 --broadcast --private-key $PRIVATE_KEY
contract MockBitcoinPodManagerScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address deployer = vm.addr(deployerPrivateKey);
        // Deploy mock contracts
        MockAppRegistry appRegistry = new MockAppRegistry();
        Oracle oracle = new Oracle();

        // Deploy MockBitcoinPodManager with required parameters
        MockBitcoinPodManager podManager = new MockBitcoinPodManager();
        address bitcoinPod = podManager.createPod(
            deployer,
            abi.encodePacked(address(0))
        );
        MockBitcoinPod(bitcoinPod).mint(deployer, 100000000); //1 Btc in satoshis
        vm.stopBroadcast();

        // Log deployed contract addresses
        console.log("MockAppRegistry deployed to:", address(appRegistry));
        console.log("Oracle deployed to:", address(oracle));
        console.log("MockBitcoinPodManager deployed to:", address(podManager));
        console.log("BitcoinPod deployed to:", bitcoinPod);
    }
}

// forge script script/cdp/CdpController.s.sol:DeployCDP --fork-url http://localhost:8545 --broadcast --private-key $PRIVATE_KEY
contract DeployCDP is Script {
    address constant _BITCOIN_POD_MANAGER =
        0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e;
    address constant _ORACLE = 0x610178dA211FEF7D417bC0e6FeD39F05609AD788;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer:", deployer);
        vm.startBroadcast(deployerPrivateKey);
        // Deploy timelock
        CDP cdp = new CDP(_BITCOIN_POD_MANAGER, _ORACLE);
        console.log("CDP deployed at:", address(cdp));

        vm.stopBroadcast();
    }
}

// forge script script/cdp/CdpController.s.sol:CdpControllerScript --fork-url http://localhost:8545 --broadcast --private-key $PRIVATE_KEY
contract CdpControllerScript is Script {
    address constant _BITCOIN_POD_MANAGER =
        0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e;
    // address constant _ORACLE = 0x9a6cB103eBA215A7bAB04D1131639b77d2a6AB41;
    address constant _BITCOIN_POD = 0x8dAF17A20c9DBA35f005b6324F493785D239719d;
    address constant _APP_ADDRESS = 0x9A676e781A523b5d0C0e43731313A708CB607508;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        CDP cdp = CDP(_APP_ADDRESS);
        MockBitcoinPodManager(_BITCOIN_POD_MANAGER).delegatePod(
            _BITCOIN_POD,
            address(_APP_ADDRESS)
        );
        uint256 debtAmount = 500000; // 5000 usd
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
