// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@bitdsm/core/AppRegistry.sol";

contract InitializeAppRegistry is Script {
    address constant APP_REGISTRY = 0x67fF1A0f47Ba0e7b4D2c96546F97EaACc9Db129E;
    address constant PROXY_ADMIN = 0x742d35Cc6634C0532925a3b844Bc454e4438f44e; // Add your ProxyAdmin contract address here

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Get the implementation address through ProxyAdmin
        ProxyAdmin admin = ProxyAdmin(PROXY_ADMIN);
        address implementation = admin.getProxyImplementation(TransparentUpgradeableProxy(payable(APP_REGISTRY)));
        console.log("Implementation address:", implementation);
        
        // Create the initialization calldata
        bytes memory initData = abi.encodeWithSelector(
            AppRegistry.initialize.selector,
            deployer
        );
        
        // Call initialize through the proxy admin
        try admin.upgradeAndCall(
            TransparentUpgradeableProxy(payable(APP_REGISTRY)),
            implementation,
            initData
        ) {
            console.log("Initialization successful");
        } catch Error(string memory reason) {
            console.log("Initialization failed:", reason);
            revert(reason);
        }
        
        vm.stopBroadcast();
        
        // Verify initialization
        try AppRegistry(APP_REGISTRY).owner() returns (address currentOwner) {
            console.log("Contract owner after initialization:", currentOwner);
        } catch Error(string memory reason) {
            console.log("Failed to get owner:", reason);
        }
    }
}
