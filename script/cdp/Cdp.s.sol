// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Oracle} from "../../src/cdp/Oracle.sol";
import {CDP} from "../../src/cdp/Cdp.sol";
import {stdJson} from "forge-std/StdJson.sol";

// to deploy on local
// forge script script/cdp/Cdp.s.sol:DeployCDP --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY

// to deploy on holesky
// forge script script/cdp/Cdp.s.sol:DeployCDP --fork-url https://1rpc.io/holesky --broadcast --private-key $DEPLOYER_PRIVATE_KEY

contract DeployCDP is Script {
    string json = vm.readFile("./script/anvil-testnet/bitdsm_addresses.json");
    bytes bitcoinPodManagerBytes =
        vm.parseJson(json, ".BitcoinPodManagerProxy");
    address _BITCOIN_POD_MANAGER =
        abi.decode(bitcoinPodManagerBytes, (address));

    function run() external {
        // address _BITCOIN_POD_MANAGER = vm.envAddress(
        //     "BITCOIN_POD_MANAGER_ADDRESSES"
        // );
        // address _ORACLE = vm.envAddress("ORACLE_ADDRESS");

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer:", deployer);
        vm.startBroadcast(deployerPrivateKey);
        // Deploy timelock
        Oracle oracle = new Oracle();
        console.log("Oracle deployed at:", address(oracle));
        console.log("Oracle owner:", oracle.owner());
        CDP cdp = new CDP(_BITCOIN_POD_MANAGER, address(oracle));
        console.log("CDP deployed at:", address(cdp));

        vm.stopBroadcast();
        string memory deploymentData = string(
            abi.encodePacked(
                '{"oracle":"',
                vm.toString(address(oracle)),
                '","cdp":"',
                vm.toString(address(cdp)),
                '"}'
            )
        );
        vm.writeFile(
            "./script/anvil-testnet/cdp-addresses.json",
            deploymentData
        );
        console.log(
            "Deployment addresses written to deployment-addresses.json"
        );
    }
}
