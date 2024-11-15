// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {BitcoinTimeLockApp} from "../../src/timelock/BitcoinTimeLockApp.sol";
import {IAppRegistry} from "@bitdsm/interfaces/IAppRegistry.sol";

// Declaring contract addresses deployed on Holesky
address constant _APP_REGISTRY = 0x91677dD787cd9056c5805cBb74e271Fd83d88E61;
address constant _APP_ADDRESS = 0xE8626F6452CF09adf623663714c4F639bf13F65c;  // your deployed App address

contract RegisterApp is Script {
    BitcoinTimeLockApp public app;

    function run() external {
    // needed for signing the message for registration. 
    // should be the same as the owner of the TimeLockApp contract
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        // check if the app owner matches the signer
        if (BitcoinTimeLockApp(_APP_ADDRESS).owner() != deployer) {
            revert("App owner does not match the signer");
        }
        // check if App is already registered
        if (IAppRegistry(_APP_REGISTRY).isAppRegistered(_APP_ADDRESS)) {
            revert("App already registered");
        }
       
        // create salt and expiry for Digest Hash
        bytes32 salt = bytes32(uint256(1));
        uint256 expiry = block.timestamp + 1 days;
        app = BitcoinTimeLockApp(_APP_ADDRESS);
        vm.startBroadcast(deployerPrivateKey);
        // Try to read the digest hash with try/catch
        try IAppRegistry(_APP_REGISTRY).calculateAppRegistrationDigestHash(
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
                
                require(magicValue == 0x1626ba7e, "Signature verification failed locally");
            
            } catch Error(string memory reason) {
                console.log("\nLocal signature verification failed:", reason);
                revert();
            }
            // if verification passed, register the app
            IAppRegistry(_APP_REGISTRY).registerApp(_APP_ADDRESS, signature, salt, expiry);
            console.log("App registered successfully");
        } catch Error(string memory reason) {
            console.log("Failed to calculate digest:", reason);
        } catch {
            console.log("Failed to calculate digest (no reason)");
        }
        
        // Update App Information. Needed to display App information on BitDSM dashboard

        app.updateAppMetadataURI(" some info about app", _APP_REGISTRY);
        
        vm.stopBroadcast();
        
    }
}
