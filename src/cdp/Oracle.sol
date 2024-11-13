// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IOracle.sol";

// ... rest of the code ...
contract Oracle is IOracle {
    // price in cents
    mapping(address => uint256) private prices;
    mapping(address => uint256) private lastUpdateTimestamps;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function getPrice(address asset) external view returns (uint256 price) {
        require(prices[asset] > 0, "Price not set");
        require(
            block.timestamp - lastUpdateTimestamps[asset] <= 1 days,
            "Price is stale"
        );
        return prices[asset];
    }

    function getLastUpdateTimestamp(
        address asset
    ) external view returns (uint256 timestamp) {
        return lastUpdateTimestamps[asset];
    }

    function updatePrice(address asset, uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be greater than 0");
        prices[asset] = newPrice;
        lastUpdateTimestamps[asset] = block.timestamp;
    }
    function getLatestPrice(address priceFeed) public view returns (uint256) {
        // AggregatorV3Interface feed = AggregatorV3Interface(priceFeed);
        // (
        //     ,
        //     /* uint80 roundID */ int256 price,
        //     ,
        //     /* uint256 startedAt */ uint256 timestamp /* uint80 answeredInRound */,

        // ) = feed.latestRoundData();

        // require(price > 0, "Invalid price");
        // require(
        //     block.timestamp - timestamp <= 1 days,
        //     "Chainlink price is stale"
        // );

        uint256 randonAdd = (uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
        ) % 4001) + 1000;

        return uint256(randonAdd + 75000);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }
}
