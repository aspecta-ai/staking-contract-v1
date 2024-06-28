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
    function setDefaultInflationRate(uint256 _defaultInflationRate) external;
    function setDefaultShareDecayRate(uint256 _defaultShareDecayRate) external;
    function setDefaultRewardCut(uint256 _defaultRewardCut) external;
    function setDefaultLockPeriod(uint256 _defaultLockPeriod) external;

    /**
     * @dev Set the default lock period
     * @param _defaultLockPeriod New default lock period
     */
    function setDefaultLockPeriod(uint256 _defaultLockPeriod) external;

    // ----------- functions for the factory ------------
    /**
     * @dev Stake tokens for a dev
     * @param dev Dev address
     * @param amount Amount to stake
     */
    function stake(
        address dev,
        uint256 amount
    ) external returns (uint256, uint256);

    /**
     * @dev Withdraw tokens for a dev
     * @param dev Dev address
     */
    function withdraw(address dev) external returns (uint256, uint256, uint256);

    /**
     * @dev Claim rewards for a staker with all staked devs
     */
    function claimStakeReward() external returns (uint256);

    /**
     * @dev Claim rewards in multiple devs
     * @param devs List of devs addresses
     */
    function claimStakeReward(
        address[] calldata devs
    ) external returns (uint256);

    /**
     * @dev Claim rewards for a dev
     */
    function claimDevReward() external returns (uint256);

    /**
     * @dev Update the build index
     * @param buildIndex New build index
     */
    function updateBuildIndex(address dev, uint256 buildIndex) external;

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
     * @dev Get dev pool
     * @param dev Dev address
     * @return Address of the dev pool contract
     */
    function getPool(address dev) external view returns (address);

    /**
     * @dev Get all staked devs for a staker
     * @param user Staker address
     * @return Addresses of the staked devs
     */
    function getStakingDevs(
        address user
    ) external view returns (address[] memory);
}
