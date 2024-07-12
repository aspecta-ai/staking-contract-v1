// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

/**
 * @title IPoolFactoryGetters Interface
 * @dev Interface for the PoolFactoryGetter contract
 */
interface IPoolFactoryGetters {
    /**
     * @dev Get default lock period
     * @return Default lock period
     */
    function getDefaultLockPeriod() external view returns (uint256);

    /**
     * @dev Get the list of staked devs
     * @param user Dev/Staker address
     * @return List of staked devs
     */
    function getStakingDevs(
        address user
    ) external view returns (address[] memory);

    /**
     * @dev Get user stake stats
     * @param user Dev/Staker address
     * @return balance Available balance
     * @return totalStakingAmount Total staking amount to devs
     * @return totalStakedAmount Total staked amount by stakers
     */
    function getUserStakeStats(
        address user
    )
        external
        view
        returns (
            uint256 balance,
            uint256 totalStakingAmount,
            uint256 totalStakedAmount
        );

    /**
     * @dev Get user reward stats
     * @param user Dev/Staker address
     * @return claimableStakeRewards Claimable staker rewards
     * @return claimableDevRewards Claimable dev rewards
     */
    function getUserRewardStats(
        address user
    ) 
        external
        view
        returns (
            uint256 claimableStakeRewards,
            uint256 claimableDevRewards
        );

    /**
     * @dev Get the amount of stakes developers received
     * @param devs Address list of the devs
     * @return List of their total staked amount
     */
    function getTotalStakedAmount(
        address[] calldata devs
    ) external view returns (uint256[] memory);

    /**
     * @dev Get the rewards of the developers
     * @param devs Address list of the devs
     * @return claimableRewards List of their total claimble rewards
     */
     function getTotalStakedRewards(
        address[] calldata devs
     ) external view returns (uint256[] memory claimableRewards);

    /**
     * @dev Get the amount of rewards received each block for a new staker
     * @param devs Address list of the developers
     * @return List of rewards per block
     */
    function getStakeRewardPerBlock(
        address[] calldata devs
    ) external view returns (uint256[] memory);

    /**
     * @dev Get staked history on a dev
     * @param stakers List of staker's address
     * @param dev address of the dev
     * @return stakeAmounts List of stake amount
     */
     function getStakedHistoryOnDev(
        address[] calldata stakers,
        address dev
     ) external view returns (uint256[] memory stakeAmounts);

    /**
     * @dev Get staker's staking history
     * @param staker Address of the staker
     * @param devs List of developer's address
     * @return stakeAmounts List of stake amount
     * @return claimableStakeRewards List of claimable staking rewards
     * @return unlockTimes List of stake unlock time
     * @return shares List of shares
     * @return rewardsPerBlock List of reward per block
     */
    function getStakingHistory(
        address staker,
        address[] calldata devs
    )
        external
        view
        returns (
            uint256[] memory stakeAmounts,
            uint256[] memory claimableStakeRewards,
            uint256[] memory unlockTimes,
            uint256[] memory shares,
            uint256[] memory rewardsPerBlock
        );

    /**
     * @dev Get total staking amount
     */
    function getTotalStakingAmount() external view returns (uint256);

    /**
     * @dev Get dev reward stats
     * @param devs Dev's addresses
     * @return totalDevRewards Total received reward by devs
     * @return totalStakeRewards Total distributed rewards to staker by devs
     */
    function getTotalAccRewards(
        address[] calldata devs
    ) external view returns (uint256[] memory, uint256[] memory);
}
