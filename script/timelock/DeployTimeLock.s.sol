// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "../../src/timelock/BitcoinTimeLockApp.sol";

contract DeployTimeLock is Script {
    
    address constant _BITCOIN_POD_MANAGER = 0x96EAE70bC21925DdE05602c87c4483579205B1F6;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        // Deploy timelock
        BitcoinTimeLockApp timelock = new BitcoinTimeLockApp(_BITCOIN_POD_MANAGER, deployer);
        console.log("BitcoinTimeLockApp deployed at:", address(timelock));
        
        vm.stopBroadcast();
    }
}
