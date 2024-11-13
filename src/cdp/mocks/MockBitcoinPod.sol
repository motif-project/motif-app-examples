// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IBitcoinPod} from "@bitdsm/interfaces/IBitcoinPod.sol";
contract MockBitcoinPod is IBitcoinPod, OwnableUpgradeable {
    bool public locked;
    bytes public signedWithdrawTx;
    address public operator;
    bytes public operatorBtcPubKey;
    bytes public bitcoinAddress;
    uint256 public bitcoinBalance;
    address public immutable manager;
    bytes public signedBitcoinWithdrawTransaction;

    constructor(address _owner, address _manager) {
        _transferOwnership(_owner);
        operator = _owner;
        manager = _manager;
        locked = false;
    }

    function getBitcoinAddress() external pure returns (bytes memory) {
        return "";
    }

    function getOperatorBtcPubKey() external pure returns (bytes memory) {
        return "";
    }

    function getOperator() external pure returns (address) {
        return address(0);
    }

    function getBitcoinBalance() external view returns (uint256) {
        return bitcoinBalance;
    }

    function lock() external {
        locked = true;
    }

    function unlock() external {
        locked = false;
    }

    function isLocked() external view returns (bool) {
        return locked;
    }

    function mint(address, uint256 amount) external {
        bitcoinBalance += amount;
    }

    function burn(address, uint256 amount) external {
        bitcoinBalance -= amount;
    }

    function getSignedBitcoinWithdrawTransaction()
        external
        view
        returns (bytes memory)
    {
        return signedWithdrawTx;
    }

    function setSignedBitcoinWithdrawTransaction(
        bytes calldata _signedWithdrawTx
    ) external {
        signedWithdrawTx = _signedWithdrawTx;
    }
}
