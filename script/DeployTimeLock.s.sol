// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "../src/timelock/BitcoinTimelockApp.sol";
import "@bitdsm/core/AppRegistry.sol";

contract DeployTimeLock is Script {
    address constant BITCOIN_POD_MANAGER = 0x78A618ef70dF03104D55D84E8EB2100A869c1a45;
    address constant APP_REGISTRY = 0xF4E2f70806628040C19BC041192Be7F2C798AA9E;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast();
        
        // Check if AppRegistry is initialized
        try OwnableUpgradeable(APP_REGISTRY).owner() returns (address owner) {
            console.log("AppRegistry owner:", owner);
        } catch {
            console.log("AppRegistry not initialized");
            vm.stopBroadcast();
            return;
        }
        
        // Deploy timelock
        BitcoinTimelockApp timelock = new BitcoinTimelockApp(BITCOIN_POD_MANAGER);
        console.log("BitcoinTimelockApp deployed at:", address(timelock));
        
        bytes32 salt = bytes32(uint256(1));
        uint256 expiry = block.timestamp + 1 hours;
        
        // Try to read the digest hash with try/catch
        try IAppRegistry(APP_REGISTRY).calculateAppRegistrationDigestHash(
            address(timelock),
            address(APP_REGISTRY),
            salt,
            expiry
        ) returns (bytes32 digestHash) {
            console.log("Digest Hash:", vm.toString(digestHash));
            
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(deployerPrivateKey, digestHash);
            if (v < 27) v += 27;
            bytes memory signature = abi.encodePacked(r, s, v);
            
            IAppRegistry(APP_REGISTRY).registerApp(address(timelock), signature, salt, expiry);
            console.log("App registered successfully");
        } catch Error(string memory reason) {
            console.log("Failed to calculate digest:", reason);
        } catch {
            console.log("Failed to calculate digest (no reason)");
        }
        
        vm.stopBroadcast();
    }
}
