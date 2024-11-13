// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Oracle} from "../../src/cdp/Oracle.sol";
import {console} from "forge-std/console.sol";
contract OracleScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Oracle oracle = new Oracle();
        console.log("Oracle deployed at:", address(oracle));
        console.log("Oracle owner:", oracle.owner());
        console.log(
            "Oracle price:",
            oracle.getLatestPrice(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c)
        );
        vm.stopBroadcast();
    }
}
