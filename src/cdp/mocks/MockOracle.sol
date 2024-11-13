// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IOracle.sol";

contract MockOracle is IOracle {
    mapping(address => uint256) private prices;
    mapping(address => uint256) private lastUpdateTimestamps;

    function getPrice(address asset) external view returns (uint256 price) {
        return prices[asset];
    }

    function getLastUpdateTimestamp(
        address asset
    ) external view returns (uint256 timestamp) {
        return lastUpdateTimestamps[asset];
    }

    function updatePrice(address asset, uint256 newPrice) external {
        prices[asset] = newPrice;
        lastUpdateTimestamps[asset] = block.timestamp;
    }

    function getLatestPrice(address priceFeed) external view returns (uint256) {
        return prices[priceFeed];
    }
}
