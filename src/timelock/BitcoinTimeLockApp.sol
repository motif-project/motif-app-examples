// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@bitdsm/interfaces/IBitcoinPod.sol";
import "@bitdsm/interfaces/IBitcoinPodManager.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

contract BitcoinTimelockApp is Ownable, IERC1271 {
    IBitcoinPodManager public immutable podManager;
    
    // Mapping of pod address to unlock timestamp
    mapping(address => uint256) public podUnlockTimes;
    
    event PodLocked(address indexed pod, uint256 unlockTime);
    event PodUnlocked(address indexed pod);

    // Add magic value constants for EIP-1271
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;
    bytes4 constant internal INVALID_SIGNATURE = 0xffffffff;

    constructor(address _podManager) {
        podManager = IBitcoinPodManager(_podManager);
    }

    function lockPodUntil(address pod, uint256 unlockTime) external {
        // Instead of checking owner, check if pod is delegated to this app
        require(IBitcoinPodManager(podManager).podToApp(pod) == address(this), "Pod not delegated to this app");
        require(unlockTime > block.timestamp, "Unlock time must be in future");
        
        podUnlockTimes[pod] = unlockTime;
        IBitcoinPodManager(podManager).lockPod(pod);
    }

    function unlockPod(address pod) external {
        require(block.timestamp >= podUnlockTimes[pod], "Time lock not expired");
        require(msg.sender == IBitcoinPod(pod).owner(), "Not pod owner");
        
        podManager.unlockPod(pod);
        delete podUnlockTimes[pod];
        
        emit PodUnlocked(pod);
    }

    // Add isValidSignature function for EIP-1271
    function isValidSignature(bytes32 _hash, bytes memory _signature) 
        external 
        view 
        override 
        returns (bytes4) 
    {
        // Recover the signer from the signature
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        address signer = ecrecover(_hash, v, r, s);
        
        // Check if the signer is the owner
        if (signer == owner()) {
            return MAGICVALUE;
        }
        return INVALID_SIGNATURE;
    }

    // Helper function to split signature
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
