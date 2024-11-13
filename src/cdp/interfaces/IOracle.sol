// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Gets the current price of an asset
     * @param asset The address of the asset to get the price for
     * @return price The current price of the asset
     */
    function getPrice(address asset) external view returns (uint256 price);

    /**
     * @notice Gets the latest timestamp when the price was updated
     * @param asset The address of the asset
     * @return timestamp The timestamp of the last price update
     */
    function getLastUpdateTimestamp(
        address asset
    ) external view returns (uint256 timestamp);

    /**
     * @notice Updates the price of an asset
     * @param asset The address of the asset to update
     * @param newPrice The new price of the asset
     */
    function updatePrice(address asset, uint256 newPrice) external;
    /**
     * @notice Updates the price of an asset
     * @param priceFeed The address of the asset to get
     */
    function getLatestPrice(address priceFeed) external view returns (uint256);
}
