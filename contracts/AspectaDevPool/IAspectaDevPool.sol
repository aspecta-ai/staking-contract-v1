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

    function getClaimableStakeReward(address staker) external view returns (uint256);

    function getClaimableDevReward() external view returns (uint256);
}