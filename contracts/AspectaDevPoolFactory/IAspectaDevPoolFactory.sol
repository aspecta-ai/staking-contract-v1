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
     * @notice Set the default shareCoeff
     * @param _defaultShareCoeff New default shareCoeff
     */
    function setDefaultShareCoeff(
        uint256 _defaultShareCoeff
    ) external returns (uint256);

    /**
     * @notice Set the default inflationRate
     * @param _defaultInflationRate New default inflationRate
     */
    function setDefaultInflationRate(
        uint256 _defaultInflationRate
    ) external returns (uint256);

    /**
     * @notice Set the default maxPPM
     * @param _defaultMaxPPM New default maxPPM
     */
    function setDefaultMaxPPM(
        uint256 _defaultMaxPPM
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
     * @dev Claim rewards for a dev/staker with all staked devs
     */
    function claimRewards() external;

    /**
     * @dev Claim rewards in multiple devs
     * @param devs List of devs addresses
     */
    function claimRewards(address[] calldata devs) external;

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
