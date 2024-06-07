// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

interface IAspectaDevPoolFactory {
    /// @notice Emmitted when a new pool is created
    event DevPoolCreated(address indexed dev, address indexed poolAddress);

    /// @notice Emmitted when staking is done
    event DevStaked(
        address indexed devAddress,
        address indexed stakerAddress,
        uint256 stakeAmount,
        uint256 shareAmount,
        uint256 totalStake,
        uint256 totalShare
    );

    /// @notice Emmitted when withdrawal is done
    event StakeWithdrawn(
        address indexed devAddress,
        address indexed stakerAddress,
        uint256 stakeAmount,
        uint256 shareAmount,
        uint256 totalStake,
        uint256 totalShare
    );

    /// @notice Emmitted when rewards are claimed
    event RewardClaimed(
        address indexed devAddress,
        address indexed stakerAddress,
        uint256 claimedAmount
    );

    /**
     * @dev Create a new pool for a dev
     * @notice This function will be called in `stake` if pool does not exist
     * @param dev Dev address
     */
    function createPool(address dev) internal returns (address);

    /**
     * @dev Stake tokens for a dev
     * @param dev Dev address
     * @param amount Amount to stake
     */
    function stake(address dev, uint256 amount) external;

    /**
     * @dev Withdraw tokens for a dev
     * @param dev Dev address
     * @param amount Amount to withdraw
     */
    function withdraw(address dev, uint256 amount) external;

    /**
     * @dev Claim rewards for a dev/staker with all staked devs
     */
    function claimRewards() external;

    /**
     * @dev Claim rewards in multiple devs
     * @param devs List of devs addresses
     */
    function claimRewards(address[] devs) external;

    /**
     * @dev Get total unclaimed rewards for a dev/staker
     * @param user Dev/Staker address
     */
    function getTotalUnclaimedRewards(
        address user
    ) external view returns (uint256);

    /**
     * @dev Get total staked amount for a dev/staker
     * @param user Dev/Staker address
     */
    function getStakingList(
        address user
    ) external view returns (address[] memory, uint256[] memory);
}
