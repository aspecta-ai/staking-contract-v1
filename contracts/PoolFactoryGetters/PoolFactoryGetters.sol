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
     * @dev Get default lock period
     * @return Default lock period
     */
    function getDefaultLockPeriod() external view returns (uint256) {
        return aspectaDevPoolFactory.getDefaultLockPeriod();
    }

    /**
     * @dev Get the list of staked devs
     * @param user Dev/Staker address
     * @return List of staked devs
     */
    function getStakingDevs(
        address user
    ) external view returns (address[] memory) {
        return aspectaDevPoolFactory.getStakingDevs(user);
    }

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
        )
    {
        balance = aspectaBuildingPoint.balanceOf(user);

        address devPoolAddress = aspectaDevPoolFactory.getPool(user);
        if (devPoolAddress != address(0)) {
            totalStakedAmount = aspectaBuildingPoint.balanceOf(devPoolAddress);
        }

        AspectaDevPool devPool;
        uint256 stakingAmount;
        address[] memory stakingDevs = aspectaDevPoolFactory.getStakingDevs(
            user
        );
        for (uint32 i = 0; i < stakingDevs.length; i++) {
            devPool = AspectaDevPool(
                aspectaDevPoolFactory.getPool(stakingDevs[i])
            );

            if (address(devPool) == address(0)) {
                continue;
            }

            (stakingAmount, ,) = devPool.getStakerState(user);
            totalStakingAmount += stakingAmount;
        }
    }

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
        )
    {
        AspectaDevPool devPool = AspectaDevPool(
            aspectaDevPoolFactory.getPool(user)
        );
        if (address(devPool) != address(0)) {
            claimableDevRewards = devPool.getClaimableDevReward();
        }

        address[] memory stakingDevs = aspectaDevPoolFactory.getStakingDevs(
            user
        );
        for (uint32 i = 0; i < stakingDevs.length; i++) {
            devPool = AspectaDevPool(
                aspectaDevPoolFactory.getPool(stakingDevs[i])
            );

            if (address(devPool) == address(0)) {
                continue;
            }

            claimableStakeRewards += devPool.getClaimableStakeReward(user);
        }
    }

    /**
     * @dev Get the amount of stakes developers received
     * @param devs Address list of the devs
     * @return totalStakedAmount List of their total staked amount
     */
    function getTotalStakedAmount(
        address[] calldata devs
    ) external view returns (uint256[] memory totalStakedAmount) {
        require(
            devs.length <= 100,
            "AspectaDevPoolFactory: Exceeds limit of 100 addresses"
        );

        totalStakedAmount = new uint256[](devs.length);

        address devPoolAddress;
        for (uint32 i = 0; i < devs.length; i++) {
            devPoolAddress = aspectaDevPoolFactory.getPool(devs[i]);
            if (devPoolAddress == address(0)) {
                totalStakedAmount[i] = 0;
                continue;
            }

            totalStakedAmount[i] = aspectaBuildingPoint.balanceOf(
                aspectaDevPoolFactory.getPool(devs[i])
            );
        }
    }

    /**
     * @dev Get the rewards of the developers
     * @param devs Address list of the devs
     * @return claimableRewards List of their total claimble rewards
     */
     function getTotalStakedRewards(
        address[] calldata devs
     ) external view returns (uint256[] memory claimableRewards) {
        require(
            devs.length <= 50,
            "AspectaDevPoolFactory: Exceeds limit of 50 addresses"
        );

        claimableRewards = new uint256[](devs.length);

        AspectaDevPool devPool;
        for (uint32 i = 0; i < devs.length; i++) {
            devPool = AspectaDevPool(aspectaDevPoolFactory.getPool(devs[i]));

            if (address(devPool) == address(0)) {
                claimableRewards[i] = 0;
                continue;
            }

            claimableRewards[i] = devPool.getClaimableDevReward();
        }
     }

    /**
     * @dev Get the amount of rewards received each block for a new staker
     * @param devs Address list of the developers
     * @return rewardsPerBlock List of rewards per block
     */
    function getStakeRewardPerBlock(
        address[] calldata devs
    ) external view returns (uint256[] memory rewardsPerBlock) {
        require(
            devs.length <= 100,
            "AspectaDevPoolFactory: Exceeds limit of 100 addresses"
        );

        rewardsPerBlock = new uint256[](devs.length);

        AspectaDevPool devPool;
        for (uint32 i = 0; i < devs.length; i++) {
            devPool = AspectaDevPool(aspectaDevPoolFactory.getPool(devs[i]));

            if (address(devPool) == address(0)) {
                rewardsPerBlock[i] = 0;
            } else {
                rewardsPerBlock[i] = devPool.getStakeRewardPerBlock();
            }
        }
    }

    /**
     * @dev Get staked history on a dev
     * @param stakers List of staker's address
     * @param dev address of the dev
     * @return stakeAmounts List of stake amount
     */
     function getStakedHistoryOnDev(
        address[] calldata stakers,
        address dev
     ) external view returns (uint256[] memory stakeAmounts) {
        require(
            stakers.length <= 100,
            "AspectaDevPoolFactory: Exceeds limit of 100 addresses"
        );

        stakeAmounts = new uint256[](stakers.length);
        AspectaDevPool devPool = AspectaDevPool(
            aspectaDevPoolFactory.getPool(dev)
        );

        if (address(devPool) == address(0)) {
            for (uint32 i = 0; i < stakers.length; i++) {
                stakeAmounts[i] = 0;
            }
        } else {
            for (uint32 i = 0; i < stakers.length; i++) {
                (stakeAmounts[i], ,) = devPool.getStakerState(stakers[i]);
            }
        }
     }

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
        )
    {
        require(
            devs.length <= 100,
            "AspectaDevPoolFactory: Exceeds limit of 100 addresses"
        );

        stakeAmounts = new uint256[](devs.length);
        claimableStakeRewards = new uint256[](devs.length);
        unlockTimes = new uint256[](devs.length);
        shares = new uint256[](devs.length);
        rewardsPerBlock = new uint256[](devs.length);

        AspectaDevPool devPool;
        for (uint32 i = 0; i < devs.length; i++) {
            devPool = AspectaDevPool(aspectaDevPoolFactory.getPool(devs[i]));
            if (address(devPool) == address(0)) {
                claimableStakeRewards[i] = 0;
                stakeAmounts[i] = 0;
                unlockTimes[i] = 0;
                shares[i] = 0;
                rewardsPerBlock[i] = 0;
                continue;
            }

            claimableStakeRewards[i] = devPool.getClaimableStakeReward(staker);
            (stakeAmounts[i], unlockTimes[i], shares[i]) = devPool
                .getStakerState(staker);
            rewardsPerBlock[i] = devPool.getStakeRewardPerBlock(staker);
        }
    }

    /**
     * @dev Get total staking amount
     */
    function getTotalStakingAmount() external view returns (uint256) {
        return aspectaDevPoolFactory.totalStakingAmount();
    }

    /**
     * @dev Get dev and staker's total accumulated rewards
     * @param devs Dev's addresses
     * @return totalDevRewards Total received reward by devs
     * @return totalStakeRewards Total distributed rewards to staker by devs
     */
    function getTotalAccRewards(
        address[] calldata devs
    )
        external
        view
        returns (
            uint256[] memory totalDevRewards,
            uint256[] memory totalStakeRewards
        )
    {
        require(
            devs.length <= 20,
            "AspectaDevPoolFactory: Exceeds limit of 20 addresses"
        );

        totalDevRewards = new uint256[](devs.length);
        totalStakeRewards = new uint256[](devs.length);

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
    }

    /**
     * @dev Upgrade the contract
     * @param newImplementation New implementation address
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
