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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

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

    /// Internal functions

    function _getRewardPerBlock() internal view returns (uint256) {
        return
            (IAspectaBuildingPoint(aspectaToken).balanceOf(address(this)) *
                inflationRate *
                buildIndex) /
            MAX_PPB /
            MAX_PPB;
    }

    function _updateRewardPool() internal {
        uint256 blockNum = block.number;
        if (blockNum <= lastRewardedBlockNum) {
            return;
        }
        if (totalSupply() == 0) {
            lastRewardedBlockNum = blockNum;
            return;
        }

        uint256 reward = _getRewardPerBlock() *
            (blockNum - lastRewardedBlockNum);
        totalAccReward += reward;
        rewardPerShare += (reward * FIXED_POINT_SCALING_FACTOR) / totalSupply();
        lastRewardedBlockNum = blockNum;
    }

    function _claimStakeReward(
        address _staker
    ) internal returns (uint256 reward) {
        StakerState storage stakerState = stakerStates[_staker];
        uint256 shareAmount = balanceOf(_staker);
        if (shareAmount > 0) {
            reward = ((MAX_PPB - rewardCut) *
                (rewardPerShare - stakerState.lastRewardPerShare) *
                shareAmount) /
                MAX_PPB /
                FIXED_POINT_SCALING_FACTOR;
            IAspectaBuildingPoint(aspectaToken).mint(_staker, reward);
            IAspectaDevPoolFactory(factory).emitStakeRewardClaimed(
                developer,
                _staker,
                reward
            );
        }
        stakerState.lastRewardPerShare = rewardPerShare;
    }

    function _claimDevReward() internal returns (uint256 reward) {
        reward = (rewardCut * (totalAccReward - devLastReward)) / MAX_PPB;
        IAspectaBuildingPoint(aspectaToken).mint(developer, reward);
        devLastReward = totalAccReward;
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

    function _stake(
        address _staker,
        uint256 _amount
    ) internal returns (uint256 shareAmount) {
        IAspectaBuildingPoint token = IAspectaBuildingPoint(aspectaToken);
        shareAmount =
            (_stakeToShare(_amount) * shareCoeff) /
            FIXED_POINT_SCALING_FACTOR;
        token.transferFrom(_staker, address(this), _amount);
        _mint(_staker, shareAmount);
        stakerStates[_staker].stakeAmount += _amount;
        stakerStates[_staker].unlockTime = block.timestamp + defaultLockPeriod;
        IAspectaDevPoolFactory(factory).emitDevStaked(
            developer,
            _staker,
            _amount,
            shareAmount,
            token.balanceOf(address(this)),
            totalSupply()
        );
    }

    function _withdraw(
        address _staker
    ) internal returns (uint256 stakeAmount, uint256 shareAmount) {
        require(
            stakerStates[_staker].unlockTime <= block.timestamp,
            "AspectaDevPool: Stake is locked"
        );
        IAspectaBuildingPoint token = IAspectaBuildingPoint(aspectaToken);
        StakerState storage stakerState = stakerStates[_staker];
        shareAmount = balanceOf(_staker);
        stakeAmount = stakerState.stakeAmount;
        token.transfer(_staker, stakeAmount);
        _burn(_staker, shareAmount);
        stakerState.stakeAmount = 0;
        stakerState.unlockTime = 0;

        if (token.balanceOf(address(this)) > 0) {
            shareCoeff =
                (totalSupply() * FIXED_POINT_SCALING_FACTOR) /
                _expectedTotalShare(token.balanceOf(address(this)));
        } else {
            shareCoeff = FIXED_POINT_SCALING_FACTOR;
        }
        IAspectaDevPoolFactory(factory).emitStakeWithdrawn(
            developer,
            _staker,
            stakeAmount,
            shareAmount,
            token.balanceOf(address(this)),
            totalSupply()
        );
    }

    /// External functions

    function stake(
        address staker,
        uint256 amount
    )
        external
        onlyOwner
        returns (uint256 claimedReward, uint256 shareAmount)
    {
        _updateRewardPool();
        claimedReward = _claimStakeReward(staker);
        shareAmount = _stake(staker, amount);
    }

    function withdraw(
        address staker
    )
        external
        onlyOwner
        returns (
            uint256 claimedReward,
            uint256 stakeAmount,
            uint256 shareAmount
        )
    {
        _updateRewardPool();
        claimedReward = _claimStakeReward(staker);
        (stakeAmount, shareAmount) = _withdraw(staker);
    }

    function claimStakeReward(
        address staker
    ) external onlyOwner returns (uint256 claimedReward) {
        _updateRewardPool();
        claimedReward = _claimStakeReward(staker);
    }

    function claimDevReward()
        external
        onlyOwner
        returns (uint256 claimedReward)
    {
        _updateRewardPool();
        claimedReward = _claimDevReward();
    }

    function updateBuildIndex(uint256 _buildIndex) external onlyOwner {
        buildIndex = _buildIndex;
    }

    /// Getters

    function getClaimableStakeReward(
        address staker
    ) external view returns (uint256) {
        uint256 blockNum = block.number;
        uint256 currentRewardPerShare = rewardPerShare;
        if (totalSupply() > 0) {
            uint256 reward = _getRewardPerBlock() *
                (blockNum - lastRewardedBlockNum);
            currentRewardPerShare +=
                (reward * FIXED_POINT_SCALING_FACTOR) /
                totalSupply();
        }
        return
            ((MAX_PPB - rewardCut) *
                balanceOf(staker) *
                (currentRewardPerShare -
                    stakerStates[staker].lastRewardPerShare)) /
            MAX_PPB /
            FIXED_POINT_SCALING_FACTOR;
    }

    function getClaimableDevReward() external view returns (uint256) {
        uint256 blockNum = block.number;
        uint256 currentReward = totalAccReward;
        if (totalSupply() > 0) {
            uint256 reward = _getRewardPerBlock() *
                (blockNum - lastRewardedBlockNum);
            currentReward += reward;
        }
        return (rewardCut * (currentReward - devLastReward)) / MAX_PPB;
    }

    function getStakeRewardPerBlock() external view returns (uint256) {
        uint256 defaultShares = _stakeToShare(10 ** decimals());
        return
            (defaultShares * (MAX_PPB - rewardCut) * _getRewardPerBlock()) /
            MAX_PPB /
            (totalSupply() + defaultShares);
    }

    function getStakeRewardPerBlock(
        address staker
    ) external view returns (uint256) {
        return
            (balanceOf(staker) * (MAX_PPB - rewardCut) * _getRewardPerBlock()) /
            MAX_PPB /
            totalSupply();
    }

    /**
     * @dev Get staker's state
     * @param staker Staker's address
     * @return stakeAmount Staker's stake amount
     * @return unlockTime Staker's unlock time
     * @return shareAmount Staker's share amount
     */
    function getStakerState(
        address staker
    ) external view returns (uint256, uint256, uint256) {
        return (
            stakerStates[staker].stakeAmount,
            stakerStates[staker].unlockTime,
            balanceOf(staker)
        );
    }

    /**
     * @dev Get build index
     * @return Build index
     */
    function getBuildIndex() external view returns (uint256) {
        return buildIndex;
    }

    /**
     * @dev Get dev reward stats
     * @return totalDevReward Total received reward by dev
     * @return totalStakeReward Total distributed reward to staker by dev
     */
    function getTotalAccRewards()
        external
        view
        returns (uint256 totalDevReward, uint256 totalStakeReward)
    {
        uint256 currentTotalAccReward = totalAccReward;
        if (totalSupply() > 0) {
            currentTotalAccReward +=
                (block.number - lastRewardedBlockNum) *
                _getRewardPerBlock();
        }

        totalDevReward = ((rewardCut * currentTotalAccReward) / MAX_PPB);
        totalStakeReward = currentTotalAccReward - totalDevReward;
    }

    /// Setters

    // @dev Set default lock period
    function setDefaultLockPeriod(
        uint256 _defaultLockPeriod
    ) external onlyOwner {
        defaultLockPeriod = _defaultLockPeriod;
    }
}
