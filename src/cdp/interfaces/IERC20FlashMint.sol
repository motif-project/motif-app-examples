// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20FlashMint {
    /**
     * @dev Returns the maximum amount of tokens available for flash minting.
     * @return The maximum flash mint amount
     */
    function maxFlashMint() external view returns (uint256);

    /**
     * @dev Flash mints `amount` tokens to the caller, requiring them to return the tokens plus a fee by the end of the transaction.
     * @param amount The amount of tokens to flash mint
     */
    function flashMint(uint256 amount) external;

    /**
     * @dev Returns the fee required to flash mint tokens.
     * @param amount The amount of tokens to be flash minted
     * @return The required fee amount
     */
    function flashFee(uint256 amount) external view returns (uint256);

    /**
     * @dev Emitted when tokens are flash minted
     * @param initiator The address initiating the flash mint
     * @param amount The amount of tokens flash minted
     * @param fee The fee charged for the flash mint
     */
    event FlashMint(address indexed initiator, uint256 amount, uint256 fee);
}
