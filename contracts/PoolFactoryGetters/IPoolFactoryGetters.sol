// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

/**
 * @title IPoolFactoryGetters Interface
 * @dev Interface for the PoolFactoryGetter contract
 */
interface IPoolFactoryGetters {
    /**
     * @dev Get the list of staked devs
     * @param user Dev/Staker address
     * @return List of staked devs
     */
    function getStakedDevs(
        address user
    ) external view returns (address[] memory);

    /**
     * @dev User stake stats
     * @param user address of the dev/staker
     * @return Available balance
     * @return Total staking amount
     * @return Total staked amount
     * @return Claimable stake rewards
     * @return Claimable dev rewards
     */
    function getUserStakeStats(
        address user
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    /**
     * @dev Get the amount of stakes developers received
     * @param devs Address list of the devs
     * @return List of their total staked amount
     */
    function getTotalStakedAmount(
        address[] calldata devs
    ) external view returns (uint256[] memory);

    /**
     * @dev Get the amount of rewards received each block for a new staker
     * @param devs Address list of the developers
     * @return List of rewards per block
     */
    function getStakeRewardPerBlock(
        address[] calldata devs
    ) external view returns (uint256[] memory);

    /**
     * @dev Get staker's staking history
     * @param staker staker's address
     * @param devs list of developers
     * @return List of stake amount
     * @return List of claimable staking rewards
     * @return List of stake unlock time
     * @return List of shares
     * @return List of reward per block
     */
    function getStakingHistory(
        address staker,
        address[] calldata devs
    )
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
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
