pragma solidity ^0.8.25;

import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "./IAspectaDevPoolFactory.sol";
import "../AspectaDevPool/AspectaDevPool.sol";
import "../AspectaDevToken/AspectaDevToken.sol";

/**
 * @title AspectaDevPoolFactory
 * @dev Factory contract to create and manage interfaces for dev pools
 */
contract AspectaDevPoolFactory is IAspectaDevPoolFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    function initialize(
        address initialOwner,
        address aspTokenAddress
    ) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        aspectaDevToken = AspectaDevToken(aspTokenAddress);
    }

    /**
     * @dev Create a new pool for a dev
     * @notice This function will be called in `stake` if pool does not exist
     * @param dev Dev address
     */
    function createPool(address dev) internal override returns (address) {
        require(
            devPools[dev] == address(0),
            "AspectaDevPoolFactory: Pool already exists for dev"
        );
        // TODO: AspectaDevPool constructor may take more parameters
        AspectaDevPool pool = new AspectaDevPool(dev);
        devPools[dev] = address(pool);
        allPools.push(address(pool));

        // Grant operator role to dev
        aspectaDevToken.grantRole(
            aspectaDevToken.getRoleOperater(),
            address(pool)
        );

        emit DevPoolCreated(dev, address(pool));
        return address(pool);
    }

    /**
     * @dev Stake tokens for a dev
     * @param dev Dev address
     * @param amount Amount to stake
     */
    function stake(address dev, uint256 amount) external override {
        // If pool does not exist, create one
        if (devPools[dev] == address(0)) {
            address devPoolAddr = createPool(dev);
        }

        // Stake tokens in dev pool
        // TODO: AspectaDevPool constructor may take more parameters
        AspectaDevPool devPool = AspectaDevPool(devPoolAddr);
        devPool.stake(msg.sender, amount);
        stakedDevSet[msg.sender].add(dev);

        // Emit event
        uint256 stakeAmount = devPool.getStakes(msg.sender);
        uint256 shareAmount = devPool.getShares(msg.sender);
        emit DevStaked(
            dev,
            msg.sender,
            stakeAmount,
            shareAmount,
            aspectaDevToken.balanceOf(devPoolAddr),
            devPool.totalSupply()
        );
    }

    /**
     * @dev Withdraw tokens from a dev pool
     * @param dev Dev address
     */
    function withdraw(address dev) external override {
        require(
            devPools[dev] != address(0),
            "AspectaDevPoolFactory: Pool does not exist for dev"
        );

        // TODO: AspectaDevPool constructor may take more parameters
        AspectaDevPool devPool = AspectaDevPool(devPools[dev]);
        uint256 stakeAmount = devPool.getStakes(msg.sender);
        uint256 shareAmount = devPool.getShares(msg.sender);

        // Withdraw all staked tokens from dev pool
        devPool.withdraw(msg.sender);

        // Remove dev from staked devs
        stakedDevSet[msg.sender].remove(dev);

        emit StakeWithdrawn(
            dev,
            msg.sender,
            stakeAmount,
            shareAmount,
            aspectaDevToken.balanceOf(devPools[dev]),
            devPool.totalSupply()
        );
    }

    /**
     * @dev Claim rewards for a dev/staker with all staked devs
     */
    function claimRewards() external override {
        EnumerableSet.AddressSet stakedDevs = stakedDevSet[msg.sender];
        for (uint256 i = 0; i < stakedDevs.length(); i++) {
            dev = stakedDevs.at(i);
            claimedAmount = AspectaDevPool(devPools[dev]).claimRewards(
                msg.sender
            );
            emit RewardClaimed(dev, msg.sender, claimedAmount);
        }
    }

    /**
     * @dev Claim rewards in multiple devs
     * @notice Allows the owner to claim rewards for max 10 devs at a time
     * @param devs Dev addresses
     */
    function claimRewards(address[] calldata devs) external override {
        require(
            devs.length <= 10,
            "AspectaDevPoolFactory: Max 10 devs can be claimed at a time"
        );
        for (uint32 i = 0; i < devs.length; i++) {
            dev = devs[i];
            claimedAmount = AspectaDevPool(devPools[dev]).claimRewards(
                msg.sender
            );
            emit RewardClaimed(dev, msg.sender, claimedAmount);
        }
    }

    /**
     * @dev Get total unclaimed rewards for a dev/staker
     * @param user Dev/Staker address
     * @return Total unclaimed rewards
     */
    function getTotalUnclaimedRewards(
        address user
    ) external view override returns (uint256) {
        EnumerableSet.AddressSet stakedDevs = stakedDevSet[user];
        totalUnclaimedRewards = 0;
        for (uint256 i = 0; i < stakedDevs.length(); i++) {
            dev = stakedDevs.at(i);
            totalUnclaimedRewards += AspectaDevPool(devPools[dev])
                .getUnclaimedRewards(user);
        }
        return totalUnclaimedRewards;
    }

    /**
     * @dev Get total staked amount for a dev/staker
     * @param user Dev/Staker address
     * @return Staked devs and holding shares
     */
    function getStakingList(
        address user
    ) external view override returns (address[] memory, uint256[] memory) {
        EnumerableSet.AddressSet stakedDevs = stakedDevSet[user];
        uint256[] memory shares = new uint256[](stakedDevs.length());
        for (uint256 i = 0; i < stakedDevs.length(); i++) {
            dev = stakedDevs.at(i);
            shares[i] = AspectaDevPool(devPools[dev]).getShares(user);
        }
        return (stakedDevs.values(), shares);
    }
}
