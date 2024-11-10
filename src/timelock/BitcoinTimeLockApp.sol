// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@bitdsm/interfaces/IBitcoinPod.sol";
import "@bitdsm/core/BitcoinPodManager.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@bitdsm/libraries/EIP1271SignatureUtils.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BitcoinTimeLockApp is Ownable, IERC1271 {
    BitcoinPodManager public immutable podManager;
    
    // Mapping of pod address to unlock timestamp
    mapping(address => uint256) public podUnlockTimes;
    
    event PodLocked(address indexed pod, uint256 unlockTime);
    event PodUnlocked(address indexed pod);

    // Add magic value constants for EIP-1271
    bytes4 constant internal _MAGICVALUE = 0x1626ba7e;
    bytes4 constant internal _INVALID_SIGNATURE = 0xffffffff;

    constructor(address _podManager, address _initialOwner) {
        podManager = BitcoinPodManager(_podManager);
        require(_initialOwner != address(0), "Invalid address");
        _transferOwnership(_initialOwner);
    }

    function lockPodUntil(address pod, uint256 unlockTime) external {
        // Instead of checking owner, check if pod is delegated to this app
        require(podManager.podToApp(pod) == address(this), "Pod not delegated to this app");
        require(unlockTime > block.timestamp, "Unlock time must be in future");
        
        podUnlockTimes[pod] = unlockTime;
        podManager.lockPod(pod);
    }

    function unlockPod(address pod) external {
        require(block.timestamp >= podUnlockTimes[pod], "Time lock not expired");
        require(msg.sender == podManager.owner(), "Not pod owner");
        
        podManager.unlockPod(pod);
        delete podUnlockTimes[pod];
        
        emit PodUnlocked(pod);
    }

    // Overrides the isValidSignature function for EIP-1271
    function isValidSignature(bytes32 _hash, bytes memory _signature) 
        external 
        view 
        override 
        returns (bytes4) 
    {
        // Recover the signer from the signature
        address signer = ECDSA.recover(_hash, _signature);
        // Check if the signer is the owner
        if (signer == owner()) {
            return _MAGICVALUE;
        }
        return _INVALID_SIGNATURE;
    }

}
