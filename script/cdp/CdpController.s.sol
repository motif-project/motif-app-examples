// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {CDP} from "../../src/cdp/Cdp.sol";
import {Oracle} from "../../src/cdp/Oracle.sol";
import {console} from "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";
import "../../src/cdp/Oracle.sol";
import {IBitcoinPodManager} from "@bitdsm/interfaces/IBitcoinPodManager.sol";

// to deploy on local
// forge script script/cdp/CdpController.s.sol:CdpControllerScript --rpc-url http://localhost:8545 --broadcast --private-key $PRIVATE_KEY

// to deploy on holesky
// forge script script/cdp/CdpController.s.sol:CdpControllerScript --fork-url https://1rpc.io/holesky --broadcast --private-key $DEPLOYER_PRIVATE_KEY
contract CdpControllerScript is Script {
    address internal _BITCOIN_POD_MANAGER;
    address internal _APP_ADDRESS;

    function setUp() public {
        // // to get addresses from json files
        // string memory bitdsmRoot = vm.readFile(
        //     "script/anvil-testnet/bitdsm_addresses.json"
        // );
        // string memory cdpRoot = vm.readFile(
        //     "script/anvil-testnet/cdp-addresses.json"
        // );

        // _BITCOIN_POD_MANAGER = stdJson.readAddress(
        //     bitdsmRoot,
        //     "$.BitcoinPodManagerProxy"
        // );

        // for hardcoded addresses
        _BITCOIN_POD_MANAGER = 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e; // replace with actual address
        _APP_ADDRESS = 0x58C3a95F687B9C707C4d36a57EF680D765D28d45; // replace with actual address
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        CDP cdp = CDP(_APP_ADDRESS);
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
