// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICdp {
    /**
     * @dev Opens a new CDP with initial collateral and debt
     * @param collateralAmount Amount of collateral to deposit
     * @param debtAmount Amount of debt to generate
     */
    function openCDP(uint256 collateralAmount, uint256 debtAmount) external;

    /**
     * @dev Adds collateral to an existing CDP
     * @param amount Amount of collateral to add
     */
    function addCollateral(uint256 amount) external;

    /**
     * @dev Removes collateral from an existing CDP
     * @param amount Amount of collateral to remove
     */
    function removeCollateral(uint256 amount) external;

    /**
     * @dev Generates additional debt in an existing CDP
     * @param amount Amount of additional debt to generate
     */
    function generateDebt(uint256 amount) external;

    /**
     * @dev Repays debt in an existing CDP
     * @param amount Amount of debt to repay
     */
    function repayDebt(uint256 amount) external;

    /**
     * @dev Liquidates an unsafe CDP
     * @param owner Address of the CDP owner to liquidate
     */
    function liquidate(address owner) external;

    /**
     * @dev Returns the collateralization ratio of a CDP
     * @param owner Address of the CDP owner
     * @return The current collateralization ratio
     */
    function getCollateralRatio(address owner) external view returns (uint256);

    /**
     * @dev Returns the CDP details for a given owner
     * @param owner Address of the CDP owner
     * @return collateralAmount Amount of collateral in the CDP
     * @return debtAmount Amount of debt in the CDP
     * @return lastInterestUpdate Last time interest was updated
     */
    function getCDP(
        address owner
    )
        external
        view
        returns (
            uint256 collateralAmount,
            uint256 debtAmount,
            uint256 lastInterestUpdate
        );

    function isValidSignature(
        bytes32 _hash,
        bytes memory _signature
    ) external view returns (bytes4);

    function updateAppMetadataURI(
        string calldata metadataURI,
        address appRegistry
    ) external;
}
