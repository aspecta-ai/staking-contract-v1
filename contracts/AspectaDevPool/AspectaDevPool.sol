// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;
import "forge-std/console.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {AspectaBuildingPointUtils} from "../AspectaBuildingPoint/AspectaBuildingPointUtils.sol";
import {AspectaDevPoolStorageV1} from "./AspectaDevPoolStorage.sol";
import {IAspectaBuildingPoint} from "../AspectaBuildingPoint/IAspectaBuildingPoint.sol";
/**
 * @title AspectaDevPool
 * @dev Contract for dev pools
 */
contract AspectaDevPool is Initializable, AspectaDevPoolStorageV1 {
    uint256 private constant FIXED_POINT_SCALING_FACTOR = 1e12;

    function initialize(
        address _developer,
        address _aspToken,
        uint256 _inflationRate,
        uint256 _shareDecayRate,
        uint256 _rewardCut,
        uint256 _maxPPM
    ) public initializer {
        __ERC20_init("Aspecta Dev Pool", "ADP");
        __Ownable_init(msg.sender);
        developer = _developer;
        aspectaToken = _aspToken;
        inflationRate = _inflationRate;
        shareDecayRate = _shareDecayRate;
        rewardCut = _rewardCut;
        maxPPM = _maxPPM;
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
            maxPPM /
            maxPPM;
        rewardPerShare += (reward * FIXED_POINT_SCALING_FACTOR) / totalSupply();
        lastRewardedBlockNum = blockNum;
    }

    function _claimStakeReward() internal {
        address staker = tx.origin;
        StakerState storage stakerState = stakerStates[staker];
        uint256 shareAmount = balanceOf(staker);
        if (shareAmount > 0) {
            uint256 reward = ((maxPPM - rewardCut) *
                (rewardPerShare - stakerState.lastRewardPerShare) *
                shareAmount) /
                maxPPM /
                FIXED_POINT_SCALING_FACTOR;
            IAspectaBuildingPoint(aspectaToken).mint(staker, reward);
        }
        stakerState.lastRewardPerShare = rewardPerShare;
    }

    function _claimDevReward() internal {
        require(
            tx.origin == developer,
            "AspectaDevPool: Only developer can claim dev reward"
        );
        uint256 reward = (rewardCut *
            (rewardPerShare - devLastRewardPerShare)) /
            maxPPM /
            FIXED_POINT_SCALING_FACTOR;
        IAspectaBuildingPoint(aspectaToken).mint(tx.origin, reward);
        devLastRewardPerShare = rewardPerShare;
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

    function stake(uint256 _amount) external {
        _updateRewardPool();
        _claimStakeReward();
        IAspectaBuildingPoint token = IAspectaBuildingPoint(aspectaToken);
        address staker = tx.origin;
        uint256 shareAmount = (_stakeToShare(_amount) * shareCoeff) /
            FIXED_POINT_SCALING_FACTOR;
        token.transferFrom(staker, address(this), _amount);
        _mint(staker, shareAmount);
        stakerStates[staker].stakeAmount += _amount;
    }

    function withdraw() external {
        _updateRewardPool();
        _claimStakeReward();
        IAspectaBuildingPoint token = IAspectaBuildingPoint(aspectaToken);
        address staker = tx.origin;
        StakerState storage stakerState = stakerStates[tx.origin];
        uint256 shareAmount = balanceOf(msg.sender);
        uint256 stakeAmount = stakerState.stakeAmount;
        token.transfer(staker, stakeAmount);
        _burn(staker, shareAmount);
        stakerState.stakeAmount = 0;

        shareCoeff =
            (totalSupply() * FIXED_POINT_SCALING_FACTOR) /
            _expectedTotalShare(token.balanceOf(address(this)));
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

    function getRewardPerShare() external view returns (uint256) {
        return rewardPerShare;
    }
}
