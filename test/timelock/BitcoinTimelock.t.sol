// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../../src/timelock/BitcoinTimeLockApp.sol";
import "@bitdsm/interfaces/IBitcoinPod.sol";
import "@bitdsm/interfaces/IBitcoinPodManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BitcoinTimeLockAppTest is Test {
    BitcoinTimeLockApp public timelock;
    address constant _BITCOIN_POD_MANAGER = 0x641fF9A3d79f24fE45Fb6b7351bcB43C2e7aed44;

    address podOwner = address(0x1);
    address operator = address(0x2);
    address mockPod = address(0x3);
   
    function setUp() public {
        // Deploy timelock contract
        timelock = new BitcoinTimeLockApp(_BITCOIN_POD_MANAGER, podOwner);

        // Setup mock pod manager calls
        vm.mockCall(
            _BITCOIN_POD_MANAGER,
            abi.encodeWithSelector(IBitcoinPodManager.getPodApp.selector, mockPod),
            abi.encode(address(timelock))  // Mock that pod is delegated to timelock app
        );
        
        // vm.mockCall(
        //     _BITCOIN_POD_MANAGER,
        //     abi.encodeWithSelector(IBitcoinPodManager.getOwner.selector),
        //     abi.encode(podOwner)  // Mock pod manager owner
        // );

        vm.mockCall(
            _BITCOIN_POD_MANAGER,
            abi.encodeWithSelector(IBitcoinPodManager.lockPod.selector, mockPod),
            abi.encode()
        );
        
        vm.mockCall(
            _BITCOIN_POD_MANAGER,
            abi.encodeWithSelector(IBitcoinPodManager.unlockPod.selector, mockPod),
            abi.encode()
        );
    }

    function testLockPod() public {
        // Set caller as pod owner
        vm.prank(podOwner);

        // Lock pod for 1 day
        uint256 unlockTime = block.timestamp + 1 days;
        timelock.lockPodUntil(mockPod, unlockTime);

        // Verify unlock time
        assertEq(timelock.podUnlockTimes(mockPod), unlockTime);
    }

    function testCannotLockPodIfNotDelegated() public {
        // Mock pod not delegated to this app
        vm.mockCall(
            _BITCOIN_POD_MANAGER,
            abi.encodeWithSelector(IBitcoinPodManager.getPodApp.selector, mockPod),
            abi.encode(address(0))  // Pod not delegated
        );

        uint256 unlockTime = block.timestamp + 1 days;
        vm.expectRevert("Pod not delegated to this app");
        timelock.lockPodUntil(mockPod, unlockTime);
    }

    function testCannotLockPodInPast() public {
        vm.prank(podOwner);

        uint256 unlockTime = block.timestamp - 1; // Past timestamp
        vm.expectRevert("Unlock time must be in future");
        timelock.lockPodUntil(mockPod, unlockTime);
    }

    function testUnlockPod() public {
        // First lock the pod
        vm.startPrank(podOwner);
        uint256 unlockTime = block.timestamp + 1 days;
        timelock.lockPodUntil(mockPod, unlockTime);

        // Warp to after unlock time
        vm.warp(unlockTime + 1);

        // Try to unlock
        timelock.unlockPod(mockPod);
        vm.stopPrank();

        // Verify unlock time is cleared
        assertEq(timelock.podUnlockTimes(mockPod), 0);
    }

    function testCannotUnlockPodBeforeTime() public {
        // First lock the pod
        vm.prank(podOwner);
        uint256 unlockTime = block.timestamp + 1 days;
        timelock.lockPodUntil(mockPod, unlockTime);

        // Try to unlock before time
        vm.prank(podOwner);
        vm.expectRevert("Time lock not expired");
        timelock.unlockPod(mockPod);
    }
}
