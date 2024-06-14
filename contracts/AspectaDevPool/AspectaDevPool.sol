// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {AspectaDevPoolStorageV1} from "./AspectaDevPoolStorage.sol";
import {IAspectaBuildingPoint} from "../AspectaBuildingPoint/IAspectaBuildingPoint.sol";
import {IAspectaDevPoolFactory} from "../AspectaDevPoolFactory/IAspectaDevPoolFactory.sol";

/**
 * @title AspectaDevPool
 * @dev Contract for dev pools
 */
contract AspectaDevPool is Initializable, AspectaDevPoolStorageV1 {
    uint256 private constant FIXED_POINT_SCALING_FACTOR = 1e12;
    uint32 private constant MAX_PPB = 1e9;

    function initialize(
        address _factory,
        address _developer,
        address _aspToken,
        uint256 _inflationRate,
        uint256 _shareDecayRate,
        uint256 _rewardCut,
        uint256 _defaultLockPeriod
    ) public initializer {
        __ERC20_init("Aspecta Dev Pool", "ADP");
        __Ownable_init(msg.sender);
        factory = _factory;
        developer = _developer;
        aspectaToken = _aspToken;
        inflationRate = _inflationRate;
        shareDecayRate = _shareDecayRate;
        rewardCut = _rewardCut;
        defaultLockPeriod = _defaultLockPeriod;
        lastRewardedBlockNum = block.number;
        shareCoeff = FIXED_POINT_SCALING_FACTOR;
    }

    function _updateRewardPool() internal {
        uint256 blockNum = block.number;
        if (blockNum <= lastRewardedBlockNum) {
            return;
        }
        uint256 totalStake = IAspectaBuildingPoint(aspectaToken).balanceOf(
            address(this)
        );
        uint256 reward = (totalStake *
            (blockNum - lastRewardedBlockNum) *
            inflationRate *
            buildIndex) /
            MAX_PPB /
            MAX_PPB;
        rewardPerShare += (reward * FIXED_POINT_SCALING_FACTOR) / totalSupply();
        lastRewardedBlockNum = blockNum;
    }

    function _claimStakeReward() internal {
        address staker = tx.origin;
        StakerState storage stakerState = stakerStates[staker];
        uint256 shareAmount = balanceOf(staker);
        if (shareAmount > 0) {
            uint256 reward = ((MAX_PPB - rewardCut) *
                (rewardPerShare - stakerState.lastRewardPerShare) *
                shareAmount) /
                MAX_PPB /
                FIXED_POINT_SCALING_FACTOR;
            IAspectaBuildingPoint(aspectaToken).mint(staker, reward);
            IAspectaDevPoolFactory(factory).emitStakeRewardClaimed(
                developer,
                staker,
                reward
            );
        }
        stakerState.lastRewardPerShare = rewardPerShare;
    }

    function _claimDevReward() internal {
        require(
            tx.origin == developer,
            "AspectaDevPool: Only developer can claim dev reward"
        );
        uint256 reward = (totalSupply() *
            (rewardCut * (rewardPerShare - devLastRewardPerShare))) /
            MAX_PPB /
            FIXED_POINT_SCALING_FACTOR;
        IAspectaBuildingPoint(aspectaToken).mint(tx.origin, reward);
        devLastRewardPerShare = rewardPerShare;
        IAspectaDevPoolFactory(factory).emitDevRewardClaimed(developer, reward);
    }

    function _expectedTotalShare(
        uint256 _totalStake
    ) internal view returns (uint256) {
        return
            Math.sqrt(
                FIXED_POINT_SCALING_FACTOR *
                    FIXED_POINT_SCALING_FACTOR *
                    (1 + _totalStake / shareDecayRate)
            ) - FIXED_POINT_SCALING_FACTOR;
    }

    function _stakeToShare(uint256 _amount) internal view returns (uint256) {
        uint256 totalStake = IAspectaBuildingPoint(aspectaToken).balanceOf(
            address(this)
        );
        return
            _expectedTotalShare(totalStake + _amount) -
            _expectedTotalShare(totalStake);
    }

    function _stake(uint256 _amount) internal {
        IAspectaBuildingPoint token = IAspectaBuildingPoint(aspectaToken);
        address staker = tx.origin;
        uint256 shareAmount = (_stakeToShare(_amount) * shareCoeff) /
            FIXED_POINT_SCALING_FACTOR;
        token.transferFrom(staker, address(this), _amount);
        _mint(staker, shareAmount);
        stakerStates[staker].stakeAmount += _amount;
        stakerStates[staker].unlockTime = block.timestamp + defaultLockPeriod;
        IAspectaDevPoolFactory(factory).emitDevStaked(
            developer,
            staker,
            _amount,
            shareAmount,
            token.balanceOf(address(this)),
            totalSupply()
        );
    }

    function _withdraw() internal {
        address staker = tx.origin;
        require(
            stakerStates[staker].unlockTime <= block.timestamp,
            "AspectaDevPool: Stake is locked"
        );
        IAspectaBuildingPoint token = IAspectaBuildingPoint(aspectaToken);
        StakerState storage stakerState = stakerStates[staker];
        uint256 shareAmount = balanceOf(staker);
        uint256 stakeAmount = stakerState.stakeAmount;
        token.transfer(staker, stakeAmount);
        _burn(staker, shareAmount);
        stakerState.stakeAmount = 0;

        if (token.balanceOf(address(this)) > 0) {
            shareCoeff =
                (totalSupply() * FIXED_POINT_SCALING_FACTOR) /
                _expectedTotalShare(token.balanceOf(address(this)));
        } else {
            shareCoeff = FIXED_POINT_SCALING_FACTOR;
        }
        IAspectaDevPoolFactory(factory).emitStakeWithdrawn(
            developer,
            staker,
            stakeAmount,
            shareAmount,
            token.balanceOf(address(this)),
            totalSupply()
        );
    }

    function stake(uint256 _amount) external {
        _updateRewardPool();
        _claimStakeReward();
        _stake(_amount);
    }

    function withdraw() external {
        _updateRewardPool();
        _claimStakeReward();
        _withdraw();
    }

    function claimStakeReward() external {
        _updateRewardPool();
        _claimStakeReward();
    }

    function claimDevReward() external {
        _updateRewardPool();
        _claimDevReward();
    }

    function updateBuildIndex(uint256 _buildIndex) external onlyOwner {
        buildIndex = _buildIndex;
    }

    /// Getters

    function getClaimableStakeReward(
        address staker
    ) external view override returns (uint256) {
        uint256 blockNum = block.number;
        uint256 totalStake = IAspectaBuildingPoint(aspectaToken).balanceOf(
            address(this)
        );
        uint256 reward = (totalStake *
            (blockNum - lastRewardedBlockNum) *
            inflationRate *
            buildIndex) /
            MAX_PPB /
            MAX_PPB;
        uint256 currentRewardPerShare = rewardPerShare +
            (reward * FIXED_POINT_SCALING_FACTOR) /
            totalSupply();
        return
            ((MAX_PPB - rewardCut) *
                balanceOf(staker) *
                (currentRewardPerShare -
                    stakerStates[staker].lastRewardPerShare)) /
            MAX_PPB /
            FIXED_POINT_SCALING_FACTOR;
    }

    function getClaimableDevReward() external view override returns (uint256) {
        uint256 blockNum = block.number;
        uint256 totalStake = IAspectaBuildingPoint(aspectaToken).balanceOf(
            address(this)
        );
        uint256 reward = (totalStake *
            (blockNum - lastRewardedBlockNum) *
            inflationRate *
            buildIndex) /
            MAX_PPB /
            MAX_PPB;
        uint256 currentRewardPerShare = rewardPerShare +
            (reward * FIXED_POINT_SCALING_FACTOR) /
            totalSupply();
        return
            (rewardCut *
                totalSupply() *
                (currentRewardPerShare - devLastRewardPerShare)) /
            MAX_PPB /
            FIXED_POINT_SCALING_FACTOR;
    }

    /**
     * @dev Get staker's state
     * @param staker Staker's address
     * @return stakeAmount Staker's stake amount
     * @return unlockTime Staker's unlock time
     */
    function getStakerState(address staker)
        external
        view
        returns (uint256, uint256)
    {
        return (
            stakerStates[staker].stakeAmount,
            stakerStates[staker].unlockTime
        );
    }

    function getStakes() external view returns (uint256) {
        return stakerStates[tx.origin].stakeAmount;
    }

    /**
     * @dev Get staker's share amount
     * @param staker Staker's address
     * @return stakeAmount Staker's share amount
     */
    function getStakerShare(address staker) external view returns (uint256) {
        return balanceOf(staker);
    }

    /**
     * @dev Get building progress
     * @return Building progress
     */
    function getBuildingProgress() external view returns (uint256) {
        return buildIndex;
    }
}
