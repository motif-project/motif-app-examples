// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {CDP} from "../../src/cdp/Cdp.sol";

contract DeployCDP is Script {
    address constant _BITCOIN_POD_MANAGER =
        0x3FAB0A58446da7a0703c0856A7c05abfa5a0F964;
    address constant _ORACLE = 0x9a6cB103eBA215A7bAB04D1131639b77d2a6AB41;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer:", deployer);
        vm.startBroadcast(deployerPrivateKey);
        // Deploy timelock
        CDP cdp = new CDP(_BITCOIN_POD_MANAGER, _ORACLE);
        console.log("CDP deployed at:", address(cdp));
        // address constant _APP_REGISTRY = 0xF4E2f70806628040C19BC041192Be7F2C798AA9E;
        // address constant _APP_ADDRESS = 0xE8626F6452CF09adf623663714c4F639bf13F65c;  // your deployed App address
        // address constant _PROXY_ADMIN = 0x71e4eFEcF796bBBC562f639ADde036784F67a563;

        vm.stopBroadcast();
    }
}
