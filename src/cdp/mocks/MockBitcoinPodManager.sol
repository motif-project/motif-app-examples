// SPDX-License-Identifier: MIT
// solhint-disable-next-line
// solhint-disable no-empty-blocks, no-unused-vars, const-name-snakecase
pragma solidity ^0.8.19;

import {IBitcoinPodManager} from "@bitdsm/interfaces/IBitcoinPodManager.sol";
import {IBitcoinPod} from "@bitdsm/interfaces/IBitcoinPod.sol";
import {MockBitcoinPod} from "./MockBitcoinPod.sol";

contract MockBitcoinPodManager is IBitcoinPodManager {
    mapping(address => BitcoinDepositRequest) public podToDepositRequest;
    mapping(address => bytes) public podToWithdrawalAddress;
    mapping(address => address) public podToApp;
    mapping(address => address) public userToPod;

    function getBitcoinDepositRequest(
        address pod
    ) external view returns (BitcoinDepositRequest memory) {
        return podToDepositRequest[pod];
    }

    function getBitcoinWithdrawalAddress(
        address pod
    ) external view returns (bytes memory) {
        return podToWithdrawalAddress[pod];
    }

    function createPod(
        address operator,
        bytes memory btcAddress
    ) external returns (address) {
        address pod = address(new MockBitcoinPod(msg.sender, operator));
        userToPod[msg.sender] = pod;
        return pod;
    }

    function delegatePod(address pod, address appContract) external {
        podToApp[pod] = appContract;
    }

    function undelegatePod(address pod) external {
        delete podToApp[pod];
    }

    function lockPod(address pod) external {
        IBitcoinPod(pod).lock();
    }

    function unlockPod(address pod) external {
        IBitcoinPod(pod).unlock();
    }

    function verifyBitcoinDepositRequest(
        address pod,
        bytes32 transactionId,
        uint256 amount
    ) external {
        podToDepositRequest[pod] = BitcoinDepositRequest({
            transactionId: transactionId,
            amount: amount,
            isPending: true
        });
    }

    function confirmBitcoinDeposit(
        address pod,
        bytes32 transactionId,
        uint256 amount
    ) external {
        IBitcoinPod(pod).mint(pod, amount);
        delete podToDepositRequest[pod];
    }

    function withdrawBitcoinPSBTRequest(
        address pod,
        bytes memory withdrawAddress
    ) external {
        podToWithdrawalAddress[pod] = withdrawAddress;
        emit BitcoinWithdrawalPSBTRequest(
            pod,
            IBitcoinPod(pod).getOperator(),
            withdrawAddress
        );
    }

    function withdrawBitcoinCompleteTxRequest(
        address pod,
        bytes memory preSignedWithdrawTransaction,
        bytes memory withdrawAddress
    ) external {
        podToWithdrawalAddress[pod] = withdrawAddress;
        emit BitcoinWithdrawalCompleteTxRequest(
            pod,
            IBitcoinPod(pod).getOperator(),
            preSignedWithdrawTransaction
        );
    }

    function withdrawBitcoinAsTokens(address pod) external {
        delete podToWithdrawalAddress[pod];
        emit BitcoinWithdrawnFromPod(pod, podToWithdrawalAddress[pod]);
    }

    function setSignedBitcoinWithdrawTransactionPod(
        address pod,
        bytes memory signedBitcoinWithdrawTransaction
    ) external {
        IBitcoinPod(pod).setSignedBitcoinWithdrawTransaction(
            signedBitcoinWithdrawTransaction
        );
    }

    function getUserPod(address user) external view returns (address) {
        return userToPod[user];
    }

    function getPodApp(address pod) external view returns (address) {
        return podToApp[pod];
    }

    function getPodBitcoinAddress(
        address pod
    ) external view returns (bytes memory) {
        return IBitcoinPod(pod).getBitcoinAddress();
    }

    function getPodOperator(address pod) external view returns (address) {
        return IBitcoinPod(pod).getOperator();
    }

    function getPodOperatorBtcPubKey(
        address pod
    ) external view returns (bytes memory) {
        return IBitcoinPod(pod).getOperatorBtcPubKey();
    }

    function getPodIsLocked(address pod) external view returns (bool) {
        return IBitcoinPod(pod).isLocked();
    }

    function getAppRegistry() external view returns (address) {
        return address(0); // Mock implementation returns zero address
    }

    function getBitDSMRegistry() external view returns (address) {
        return address(0); // Mock implementation returns zero address
    }

    function getBitDSMServiceManager() external view returns (address) {
        return address(0); // Mock implementation returns zero address
    }

    function getTotalTVL() external view returns (uint256) {
        return 0; // Mock implementation returns 0
    }
}
