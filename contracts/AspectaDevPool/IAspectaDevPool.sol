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

    function stake(uint256 _amount) external;

    function withdraw() external;

    function claimStakeReward() external;

    function claimDevReward() external;

    function updateBuildIndex(uint256 _buildIndex) external;

    /// Getters
    function getClaimableStakeReward(address staker) external view returns (uint256);

    function getClaimableDevReward() external view returns (uint256);

    /**
     * @dev Get staker's state
     * @param staker Staker's address
     * @return stakeAmount Staker's stake amount
     * @return unlockTime Staker's unlock time
     */
    function getStakerState(address staker)
        external
        view
        returns (uint256, uint256);

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
    function getBuildingProgress() external view returns (uint256);
}
