// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {CDP} from "../../src/cdp/Cdp.sol";

// forge script script/cdp/Cdp.s.sol:DeployCDP --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY
contract DeployCDP is Script {
    address constant _BITCOIN_POD_MANAGER =
        0x34B40BA116d5Dec75548a9e9A8f15411461E8c70;
    address constant _ORACLE = 0xfaAddC93baf78e89DCf37bA67943E1bE8F37Bb8c;

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
