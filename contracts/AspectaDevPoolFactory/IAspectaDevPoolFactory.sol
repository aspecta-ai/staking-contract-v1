// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

interface IAspectaDevPoolFactory {
    // --------------------- beacon ---------------------
    /**
     * @notice Get the address of the implementation of the pool
     */
    function getImplementation() external view returns (address);

    /**
     * @notice Get the address of the beacon
     */
    function getBeacon() external view returns (address);

    // -------------------- business ---------------------
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

    /// @notice Emmitted when stake rewards are claimed
    event StakeRewardClaimed(
        address indexed devAddress,
        address indexed stakerAddress,
        uint256 claimedAmount
    );

    /// @notice Emmitted when dev rewards are claimed
    event DevRewardClaimed(address indexed devAddress, uint256 claimedAmount);

    // ---- setters for the default values of the pool ----
    /**
     * @notice Set the default inflationRate
     * @param _defaultInflationRate New default inflationRate
     */
    function setDefaultInflationRate(
        uint256 _defaultInflationRate
    ) external returns (uint256);

    // ----------- functions for the factory ------------
    /**
     * @dev Stake tokens for a dev
     * @param dev Dev address
     * @param amount Amount to stake
     */
    function stake(address dev, uint256 amount) external;

    /**
     * @dev Withdraw tokens for a dev
     * @param dev Dev address
     */
    function withdraw(address dev) external;

    /**
     * @dev Claim rewards for a staker with all staked devs
     */
    function claimStakeReward() external;

    /**
     * @dev Claim rewards in multiple devs
     * @param devs List of devs addresses
     */
    function claimStakeReward(address[] calldata devs) external;

    /**
     * @dev Claim rewards for a dev
     */
    function claimDevReward() external;

    /**
     * @dev Update the build index
     * @param _buildIndex New build index
     */
    function updateBuildIndex(address dev, uint256 _buildIndex) external;

    // ------------------- event router ------------------
    function emitStakeRewardClaimed(
        address devAddress,
        address stakerAddress,
        uint256 claimedAmount
    ) external;

    function emitDevRewardClaimed(
        address devAddress,
        uint256 claimedAmount
    ) external;

    function emitDevStaked(
        address devAddress,
        address stakerAddress,
        uint256 stakeAmount,
        uint256 shareAmount,
        uint256 totalStake,
        uint256 totalShare
    ) external;

    function emitStakeWithdrawn(
        address devAddress,
        address stakerAddress,
        uint256 stakeAmount,
        uint256 shareAmount,
        uint256 totalStake,
        uint256 totalShare
    ) external;

    /// getters
    /**
     * @dev Get default lock period
     * @return Default lock period
     */
     function getDefaultLockPeriod() external view returns (uint256);

    /**
     * @dev User stake stats
     * @param user Dev/Staker address
     * @return Available balance
     * @return Total staking amount
     * @return Total staked amount
     * @return Unclaimed staking rewards
     * @return Unclaimed staked rewards
     */
    function getUserStakeStats(
        address user
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    /**
     * @dev Get the amount of stakes developers received
     * @param devs Address list of the developers
     * @return List of their total staked amount
     */
    function getDevsTotalStaking(
        address[] calldata devs
    ) external view returns (uint256[] memory);

    /**
     * @dev Get user's stakes history in all developers
     * @param user staker's address
     * @param devs list of developers
     * @return List of stake amount
     * @return List of unclaimed staking rewards
     * @return List of stake unlock time
     */
    function getUserStakedList(
        address user,
        address[] calldata devs
    )
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );

    /**
     * @dev Get total claimable reward for a staker
     * @param staker Staker address
     */
    function getTotalClaimableStakeReward(
        address staker
    ) external view returns (uint256);

    /**
     * @dev Get total claimable stake reward for a dev
     */
    function getTotalClaimableDevReward() external view returns (uint256);

    /**
     * @dev Get total staked amount for a dev/staker
     * @param user Dev/Staker address
     */
    function getStakingList(
        address user
    ) external view returns (address[] memory, uint256[] memory);

    /**
     * @dev Get total staking amount
     */
    function getTotalStaking() external view returns(uint256);

    /**
     * @dev Get dev reward stats
     * @param devs Dev's addresses
     * @return totalReceivedRewards Total received reward by devs
     * @return totalDistributedRewards Total distributed rewards to staker by devs
     */
     function getDevsRewardStats(
        address[] calldata devs
    ) external view returns (uint256[] memory, uint256[] memory);
}
