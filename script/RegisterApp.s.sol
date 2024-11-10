// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {BitcoinTimeLockApp} from "../src/timelock/BitcoinTimeLockApp.sol";
import {AppRegistry} from "@bitdsm/core/AppRegistry.sol";

// Declaring contract addresses deployed on Holesky
address constant _APP_REGISTRY = 0xF4E2f70806628040C19BC041192Be7F2C798AA9E;
address constant _APP_ADDRESS = 0xE8626F6452CF09adf623663714c4F639bf13F65c;  // your deployed App address
address constant _PROXY_ADMIN = 0x71e4eFEcF796bBBC562f639ADde036784F67a563;

contract RegisterApp is Script {
    BitcoinTimeLockApp public app;
    // verify if AppRegistry is initialized
    function verifyOwnership() public view returns(bool){
        // Get proxy instance (points to implementation logic)
        AppRegistry proxy = AppRegistry(_APP_REGISTRY);
        
        // verify the initialization of AppRegistry contract
        try proxy.owner() returns (address owner) {
            console.log("AppRegistry owner:", owner);
            return true;
        } catch {
            console.log("AppRegistry not initialized");
            return false;
        }
        
    }
    function run() external {
    // needed for signing the message for registration. 
    // should be the same as the owner of the TimeLockApp contract
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        // check if the app owner matches the signer
        if (BitcoinTimeLockApp(_APP_ADDRESS).owner() != deployer) {
            revert("App owner does not match the signer");
        }
        // check if AppRegistry is initialized
        if (!verifyOwnership()) {
           revert("AppRegistry not initialized");
       }
        // check if App is already registered
        if (AppRegistry(_APP_REGISTRY).isAppRegistered(_APP_ADDRESS)) {
            revert("App already registered");
        }
       
        // create salt and expiry for Digest Hash
        bytes32 salt = bytes32(uint256(1));
        uint256 expiry = block.timestamp + 1 days;
        app = BitcoinTimeLockApp(_APP_ADDRESS);
        vm.startBroadcast(deployerPrivateKey);
        // Try to read the digest hash with try/catch
        try AppRegistry(_APP_REGISTRY).calculateAppRegistrationDigestHash(
            _APP_ADDRESS,
            _APP_REGISTRY,
            salt,
            expiry
        ) returns (bytes32 digestHash) {
            console.log("Digest Hash:", vm.toString(digestHash));
            
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(deployerPrivateKey, digestHash);
            bytes memory signature = abi.encodePacked(r, s, v);

            // lets verify the signature locally
            try app.isValidSignature(digestHash, signature) returns (bytes4 magicValue) {
            console.log("\nSignature verification result:", vm.toString(magicValue));
            require(magicValue == 0x1626ba7e, "Signature verification failed locally");
            } catch Error(string memory reason) {
            console.log("\nLocal signature verification failed:", reason);
            revert("Local signature verification failed");
            }
            // if verification passed, register the app
            AppRegistry(_APP_REGISTRY).registerApp(_APP_ADDRESS, signature, salt, expiry);
            console.log("App registered successfully");
        } catch Error(string memory reason) {
            console.log("Failed to calculate digest:", reason);
        } catch {
            console.log("Failed to calculate digest (no reason)");
        }
        
        vm.stopBroadcast();
    }
}