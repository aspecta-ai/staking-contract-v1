// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../AspectaBuildingPoint/AspectaBuildingPoint.sol";
import "../AspectaDevPool/AspectaDevPool.sol";
import "../AspectaDevPoolFactory/AspectaDevPoolFactory.sol";
import "./IPoolFactoryGetters.sol";

/**
 * @title PoolFactoryGetters
 * @dev Getters for the AspectaDevPoolFactory contract
 */
contract PoolFactoryGetters is
    Initializable,
    OwnableUpgradeable,
    IPoolFactoryGetters,
    UUPSUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    AspectaDevPoolFactory aspectaDevPoolFactory;
    AspectaBuildingPoint aspectaBuildingPoint;

    uint256[50] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        address _aspectaDevPoolFactory
    ) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        aspectaDevPoolFactory = AspectaDevPoolFactory(_aspectaDevPoolFactory);
        aspectaBuildingPoint = aspectaDevPoolFactory.aspectaBuildingPoint();
    }

    /**
     * @dev User stake stats
     * @param user Dev/Staker address
     * @return Available balance
     * @return Total staking amount
     * @return Total staked amount
     * @return Claimable stake rewards
     * @return Claimable dev rewards
     */
    function getUserStakeStats(
        address user
    ) external view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 totalStakingAmount = 0;
        uint256 totalStakedAmount = 0;
        uint256 claimableStakeRewards = 0;
        uint256 claimeableDevRewards = 0;

        AspectaDevPool devPool = AspectaDevPool(
            aspectaDevPoolFactory.getPool(user)
        );
        if (address(devPool) != address(0)) {
            totalStakedAmount = aspectaBuildingPoint.balanceOf(
                address(devPool)
            );
            claimeableDevRewards = devPool.getClaimableDevReward();
        }

        uint256 stakingAmount;
        address[] memory stakingDevs = aspectaDevPoolFactory.getStakedDevs(
            user
        );
        for (uint32 i = 0; i < stakingDevs.length; i++) {
            (stakingAmount, , ) = devPool.getStakerState(user);
            totalStakingAmount += stakingAmount;
            claimableStakeRewards += devPool.getClaimableStakeReward(user);
        }

        return (
            aspectaBuildingPoint.balanceOf(user),
            totalStakingAmount,
            totalStakedAmount,
            claimableStakeRewards,
            claimeableDevRewards
        );
    }

    /**
     * @dev Get the amount of stakes developers received
     * @param devs Address list of the devs
     * @return List of their total staked amount
     */
    function getTotalStakedAmount(
        address[] calldata devs
    ) external view returns (uint256[] memory) {
        require(
            devs.length <= 100,
            "AspectaDevPoolFactory: Exceeds limit of 100 addresses"
        );

        uint256[] memory totalStakedAmount = new uint256[](devs.length);

        for (uint32 i = 0; i < devs.length; i++) {
            totalStakedAmount[i] = aspectaBuildingPoint.balanceOf(
                aspectaDevPoolFactory.getPool(devs[i])
            );
        }

        return totalStakedAmount;
    }

    /**
     * @dev Get the amount of rewards received each block for a new staker
     * @param devs Address list of the developers
     * @return List of rewards per block
     */
    function getStakeRewardPerBlock(
        address[] calldata devs
    ) external view returns (uint256[] memory) {
        require(
            devs.length <= 100,
            "AspectaDevPoolFactory: Exceeds limit of 100 addresses"
        );

        uint256[] memory rewardsPerBlock = new uint256[](devs.length);

        AspectaDevPool devPool;
        for (uint32 i = 0; i < devs.length; i++) {
            devPool = AspectaDevPool(aspectaDevPoolFactory.getPool(devs[i]));

            if (address(devPool) == address(0)) {
                rewardsPerBlock[i] = 0;
            } else {
                rewardsPerBlock[i] = devPool.getStakeRewardPerBlock();
            }
        }

        return rewardsPerBlock;
    }

    /**
     * @dev Get the amount of rewards received each block for each staked dev for a given staker
     * @param staker Address of the staker
     * @return List of rewards per block
     */
    function getStakeRewardPerBlock(
        address staker
    ) external view returns (uint256[] memory) {
        address[] memory stakingDevs = aspectaDevPoolFactory.getStakedDevs(
            staker
        );
        uint256[] memory rewardsPerBlock = new uint256[](stakingDevs.length);

        AspectaDevPool devPool;
        for (uint256 i = 0; i < stakingDevs.length; i++) {
            devPool = AspectaDevPool(
                aspectaDevPoolFactory.getPool(stakingDevs[i])
            );

            rewardsPerBlock[i] = devPool.getStakeRewardPerBlock(staker);
        }

        return rewardsPerBlock;
    }

    /**
     * @dev Get staker's staking history
     * @param staker staker's address
     * @param devs list of developers
     * @return List of stake amount
     * @return List of claimable staking rewards
     * @return List of stake unlock time
     */
    function getStakingHistory(
        address staker,
        address[] calldata devs
    )
        external
        view
        returns (uint256[] memory, uint256[] memory, uint256[] memory)
    {
        require(
            devs.length <= 100,
            "AspectaDevPoolFactory: Exceeds limit of 100 addresses"
        );

        uint256[] memory stakeAmounts = new uint256[](devs.length);
        uint256[] memory claimableStakeRewards = new uint256[](devs.length);
        uint256[] memory unlockTimes = new uint256[](devs.length);

        AspectaDevPool devPool;
        for (uint32 i = 0; i < devs.length; i++) {
            devPool = AspectaDevPool(aspectaDevPoolFactory.getPool(devs[i]));

            claimableStakeRewards[i] = devPool.getClaimableStakeReward(staker);
            (stakeAmounts[i], unlockTimes[i], ) = devPool.getStakerState(
                staker
            );
        }

        return (stakeAmounts, claimableStakeRewards, unlockTimes);
    }

    /**
     * @dev Get total staking amount
     */
    function getTotalStakingAmount() external view returns (uint256) {
        return aspectaDevPoolFactory.totalStakingAmount();
    }

    /**
     * @dev Get staking devs and holding shares
     * @param staker Staker's address
     * @return List of staking devs
     * @return List of holding shares
     */
    function getStakingList(
        address staker
    ) external view returns (address[] memory, uint256[] memory) {
        address[] memory stakingDevs = aspectaDevPoolFactory.getStakedDevs(
            staker
        );
        uint256[] memory shares = new uint256[](stakingDevs.length);

        AspectaDevPool devPool;
        for (uint256 i = 0; i < stakingDevs.length; i++) {
            devPool = AspectaDevPool(
                aspectaDevPoolFactory.getPool(stakingDevs[i])
            );

            shares[i] = devPool.balanceOf(staker);
        }

        return (stakingDevs, shares);
    }

    /**
     * @dev Get dev reward stats
     * @param devs Dev's addresses
     * @return totalDevRewards Total received reward by devs
     * @return totalStakeRewards Total distributed rewards to staker by devs
     */
    function getTotalAccRewards(
        address[] calldata devs
    ) external view returns (uint256[] memory, uint256[] memory) {
        require(
            devs.length <= 20,
            "AspectaDevPoolFactory: Exceeds limit of 20 addresses"
        );

        uint256[] memory totalDevRewards = new uint256[](devs.length);
        uint256[] memory totalStakeRewards = new uint256[](devs.length);

        AspectaDevPool devPool;
        for (uint32 i = 0; i < devs.length; i++) {
            devPool = AspectaDevPool(aspectaDevPoolFactory.getPool(devs[i]));

            if (address(devPool) == address(0)) {
                totalDevRewards[i] = 0;
                totalStakeRewards[i] = 0;
                continue;
            }

            (totalDevRewards[i], totalStakeRewards[i]) = devPool
                .getTotalAccRewards();
        }

        return (totalDevRewards, totalStakeRewards);
    }

    /**
     * @dev Upgrade the contract
     * @param newImplementation New implementation address
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
