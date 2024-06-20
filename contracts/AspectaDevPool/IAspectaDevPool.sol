// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

/**
 * @title IAspectaDevPool Interface
 * @dev Interface for the IAspectaDevPool contract
 */
interface IAspectaDevPool {
    struct EIP712Signature {
        uint8 v; // The recovery ID.
        bytes32 r; // The x-coordinate of the nonce R.
        bytes32 s; // The signature data.
    }

    struct StakerState {
        uint256 stakeAmount;
        uint256 lastRewardPerShare;
        uint256 unlockTime;
    }

    function stake(address staker, uint256 amount) external;

    function withdraw(address staker) external;

    function claimStakeReward(address staker) external;

    function claimDevReward() external;

    function updateBuildIndex(uint256 buildIndex) external;

    /// Getters
    function getClaimableStakeReward(
        address staker
    ) external view returns (uint256);

    function getClaimableDevReward() external view returns (uint256);

    /**
     * @dev Get staker's state
     * @param staker Staker's address
     * @return stakeAmount Staker's stake amount
     * @return unlockTime Staker's unlock time
     */
    function getStakerState(
        address staker
    ) external view returns (uint256, uint256);

    /**
     * @dev Get staker's share amount
     * @param staker Staker's address
     * @return stakeAmount Staker's share amount
     */
    function getStakerShare(address staker) external view returns (uint256);

    /**
     * @dev Get building progress
     * @return Building progress
     */
    function getBuildIndex() external view returns (uint256);

    /**
     * @dev Get new staker's reward per block
     * @return Staker's reward per block
     */
    function getStakeRewardPerBlock() external view returns (uint256);

    /**
     * @dev Get existing staker's reward per block
     * @param staker Staker's address
     * @return Staker's reward per block
     */
    function getStakeRewardPerBlock(
        address staker
    ) external view returns (uint256);

    /**
     * @dev Get dev reward stats
     * @return totalReceivedReward Total received reward by dev
     * @return totalDistributedReward Total distributed reward to staker by dev
     */
    function getTotalAccRewards() external view returns (uint256, uint256);
}
