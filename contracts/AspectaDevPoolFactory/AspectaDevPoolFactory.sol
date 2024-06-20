// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./AspectaDevPoolFactoryStorage.sol";
import "../AspectaDevPool/AspectaDevPool.sol";
import "../AspectaDevPool/IAspectaDevPool.sol";
import "../AspectaBuildingPoint/AspectaBuildingPoint.sol";

/**
 * @title AspectaDevPoolFactory
 * @dev Factory contract to create and manage interfaces for dev pools
 */
contract AspectaDevPoolFactory is AspectaDevPoolFactoryStorageV1 {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        address aspTokenAddress,
        address beaconAddress,
        uint256 _defaultInflationRate,
        uint256 _defaultShareDecayRate,
        uint256 _defaultRewardCut,
        uint256 _defaultLockPeriod
    ) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(ATTESTOR_ROLE, initialOwner);

        beacon = UpgradeableBeacon(beaconAddress);

        aspectaBuildingPoint = AspectaBuildingPoint(aspTokenAddress);
        defaultInflationRate = _defaultInflationRate;
        defaultShareDecayRate = _defaultShareDecayRate;
        defaultRewardCut = _defaultRewardCut;
        defaultLockPeriod = _defaultLockPeriod;
    }

    /**
     * @dev Upgrade the contract
     * @param newImplementation New implementation address
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev Create a new pool for a dev
     * @notice This function will be called in `stake` if pool does not exist
     * @param dev Dev address
     */
    function _createPool(address dev) internal returns (address) {
        require(
            devPools[dev] == address(0),
            "AspectaDevPoolFactory: Pool already exists for dev"
        );

        // Create a new pool for the dev
        BeaconProxy poolProxy = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                AspectaDevPool(address(0)).initialize.selector,
                address(this),
                dev,
                address(aspectaBuildingPoint),
                defaultInflationRate,
                defaultShareDecayRate,
                defaultRewardCut,
                defaultLockPeriod
            )
        );
        devPools[dev] = address(poolProxy);
        allPools.push(address(poolProxy));

        // Grant operator role of AspectaBuildingPoint to pool
        aspectaBuildingPoint.grantRole(
            aspectaBuildingPoint.getOperatorRole(),
            address(poolProxy)
        );

        // Grant operator role of factory to pool
        _grantRole(OPERATOR_ROLE, address(poolProxy));

        emit DevPoolCreated(dev, address(poolProxy));
        return address(poolProxy);
    }

    /**
     * @dev Stake tokens for a dev
     * @param dev Dev address
     * @param amount Amount to stake
     */
    function stake(address dev, uint256 amount) external override {
        address devPoolAddr;
        // If pool does not exist, create one
        if (devPools[dev] == address(0)) {
            devPoolAddr = _createPool(dev);
        } else {
            devPoolAddr = devPools[dev];
        }

        // Stake tokens in dev pool
        IAspectaDevPool(devPoolAddr).stake(msg.sender, amount);
        stakedDevSet[msg.sender].add(dev);
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

        // Withdraw all staked tokens from dev pool
        IAspectaDevPool(devPools[dev]).withdraw(msg.sender);

        // Remove dev from staked devs
        stakedDevSet[msg.sender].remove(dev);
    }

    /**
     * @dev Claim rewards for a staker with all staked devs
     */
    function claimStakeReward() external override {
        EnumerableSet.AddressSet storage stakedDevs = stakedDevSet[msg.sender];
        address dev;
        for (uint256 i = 0; i < stakedDevs.length(); i++) {
            dev = stakedDevs.at(i);
            IAspectaDevPool(devPools[dev]).claimStakeReward(msg.sender);
        }
    }

    /**
     * @dev Claim rewards in multiple devs
     * @notice Allows the owner to claim rewards for max 10 devs at a time
     * @param devs Dev addresses
     */
    function claimStakeReward(address[] calldata devs) external override {
        require(
            devs.length <= 10,
            "AspectaDevPoolFactory: Max 10 devs can be claimed at a time"
        );
        address dev;
        for (uint32 i = 0; i < devs.length; i++) {
            dev = devs[i];
            IAspectaDevPool(devPools[dev]).claimStakeReward(msg.sender);
        }
    }

    /**
     * @dev Claim rewards for a dev
     */
    function claimDevReward() external override {
        require(
            devPools[msg.sender] != address(0),
            "AspectaDevPoolFactory: Pool does not exist for dev"
        );
        IAspectaDevPool(devPools[msg.sender]).claimDevReward();
    }

    /**
     * @dev Update the build index
     * @param buildIndex New build index
     */
    function updateBuildIndex(
        address dev,
        uint256 buildIndex
    ) external override onlyRole(ATTESTOR_ROLE) {
        require(
            devPools[dev] != address(0),
            "AspectaDevPoolFactory: Pool does not exist for dev"
        );
        IAspectaDevPool(devPools[dev]).updateBuildIndex(buildIndex);
    }

    // ------------------- event router ------------------
    function emitStakeRewardClaimed(
        address devAddress,
        address stakerAddress,
        uint256 claimedAmount
    ) public override onlyRole(OPERATOR_ROLE) {
        emit StakeRewardClaimed(devAddress, stakerAddress, claimedAmount);
    }

    function emitDevRewardClaimed(
        address devAddress,
        uint256 claimedAmount
    ) public override onlyRole(OPERATOR_ROLE) {
        emit DevRewardClaimed(devAddress, claimedAmount);
    }

    function emitDevStaked(
        address devAddress,
        address stakerAddress,
        uint256 stakeAmount,
        uint256 shareAmount,
        uint256 totalStake,
        uint256 totalShare
    ) public override onlyRole(OPERATOR_ROLE) {
        totalStakingAmount += stakeAmount;
        emit DevStaked(
            devAddress,
            stakerAddress,
            stakeAmount,
            shareAmount,
            totalStake,
            totalShare
        );
    }

    function emitStakeWithdrawn(
        address devAddress,
        address stakerAddress,
        uint256 stakeAmount,
        uint256 shareAmount,
        uint256 totalStake,
        uint256 totalShare
    ) public override onlyRole(OPERATOR_ROLE) {
        totalStakingAmount -= stakeAmount;
        emit StakeWithdrawn(
            devAddress,
            stakerAddress,
            stakeAmount,
            shareAmount,
            totalStake,
            totalShare
        );
    }

    // --------------------- getters ---------------------

    /**
     * @dev Get default lock period
     * @return Default lock period
     */
    function getDefaultLockPeriod() external view returns (uint256) {
        return defaultLockPeriod;
    }

    /**
     * @dev User stake stats
     * @param user Dev/Staker address
     * @return Available balance
     * @return Total staking amount
     * @return Total staked amount
     * @return Unclaimed staking rewards
     * @return Unclaimed staked rewards
     */
    function getUserStakeStats(
        address user
    ) external view returns (uint256, uint256, uint256, uint256, uint256) {
        EnumerableSet.AddressSet storage stakedDevs = stakedDevSet[user];

        uint256 stakingAmount;
        uint256 totalStakeAmount = 0; // Staker total staking amount in all devs
        uint256 totalStakedAmount = 0;
        uint256 unclaimedStakingRewards = 0;
        uint256 unclaimedStakedRewards = 0;

        if (devPools[user] != address(0)) {
            totalStakedAmount = aspectaBuildingPoint.balanceOf(devPools[user]);
            unclaimedStakedRewards = AspectaDevPool(devPools[user])
                .getClaimableDevReward();
        }

        address dev;
        for (uint32 i = 0; i < stakedDevs.length(); i++) {
            dev = stakedDevs.at(i);

            (stakingAmount, ) = AspectaDevPool(devPools[dev]).getStakerState(
                user
            );
            totalStakeAmount += stakingAmount;
            unclaimedStakingRewards += AspectaDevPool(devPools[dev])
                .getClaimableStakeReward(user);
        }

        return (
            aspectaBuildingPoint.balanceOf(user),
            totalStakeAmount,
            totalStakedAmount,
            unclaimedStakingRewards,
            unclaimedStakedRewards
        );
    }

    /**
     * @dev Get the amount of stakes developers received
     * @param devs Address list of the developers
     * @return List of their total staked amount
     */
    function getDevsTotalStaking(
        address[] calldata devs
    ) external view returns (uint256[] memory) {
        require(
            devs.length <= 100,
            "AspectaDevPoolFactory: Exceeds limit of 100 addresses"
        );

        uint256[] memory totalStaking = new uint256[](devs.length);
        for (uint32 i = 0; i < devs.length; i++) {
            totalStaking[i] = aspectaBuildingPoint.balanceOf(devPools[devs[i]]);
        }
        return totalStaking;
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
        for (uint32 i = 0; i < devs.length; i++) {
            if (devPools[devs[i]] == address(0)) {
                rewardsPerBlock[i] = 0;
            } else {
                rewardsPerBlock[i] = IAspectaDevPool(devPools[devs[i]])
                    .getStakeRewardPerBlock();
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
        EnumerableSet.AddressSet storage stakedDevs = stakedDevSet[staker];
        uint256[] memory rewardsPerBlock = new uint256[](stakedDevs.length());
        address dev;
        for (uint256 i = 0; i < stakedDevs.length(); i++) {
            dev = stakedDevs.at(i);
            rewardsPerBlock[i] = IAspectaDevPool(devPools[dev])
                .getStakeRewardPerBlock(staker);
        }
        return rewardsPerBlock;
    }

    /**
     * @dev Get user's stakes history in all developers
     * @param user staker's address
     * @param devs list of developers
     * @return List of stake amount
     * @return List of unclaimed staking rewards
     * @return List of stake unlock time
     */
    function getUserStakedList(
        address user,
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

        AspectaDevPool devPool;

        uint256[] memory stakeAmounts = new uint256[](devs.length);
        uint256[] memory unclaimedStakingRewards = new uint256[](devs.length);
        uint256[] memory unlockTimes = new uint256[](devs.length);

        for (uint32 i = 0; i < devs.length; i++) {
            devPool = AspectaDevPool(devPools[devs[i]]);

            unclaimedStakingRewards[i] = devPool.getClaimableStakeReward(user);
            (stakeAmounts[i], unlockTimes[i]) = devPool.getStakerState(user);
        }

        return (stakeAmounts, unclaimedStakingRewards, unlockTimes);
    }

    /**
     * @dev Get total staking amount
     */
    function getTotalStaking() external view returns (uint256) {
        return totalStakingAmount;
    }

    /**
     * @dev Get total claimable stake reward for a staker
     * @param staker Staker address
     * @return totalClaimableStakeReward Total claimable stake reward
     */
    function getTotalClaimableStakeReward(
        address staker
    ) external view override returns (uint256) {
        EnumerableSet.AddressSet storage stakedDevs = stakedDevSet[staker];
        uint256 totalClaimableStakeReward = 0;
        address dev;
        for (uint256 i = 0; i < stakedDevs.length(); i++) {
            dev = stakedDevs.at(i);
            totalClaimableStakeReward += IAspectaDevPool(devPools[dev])
                .getClaimableStakeReward(staker);
        }
        return totalClaimableStakeReward;
    }

    /**
     * @dev Get total claimable stake reward for a dev
     * @return totalClaimableDevReward Total claimable dev reward
     */
    function getTotalClaimableDevReward(
        address dev
    ) external view override returns (uint256) {
        if (devPools[dev] == address(0)) {
            return 0;
        }
        return IAspectaDevPool(devPools[dev]).getClaimableDevReward();
    }

    /**
     * @dev Get total staked amount for a dev/staker
     * @param user Dev/Staker address
     * @return Staked devs and holding shares
     */
    function getStakingList(
        address user
    ) external view override returns (address[] memory, uint256[] memory) {
        EnumerableSet.AddressSet storage stakedDevs = stakedDevSet[user];
        uint256[] memory shares = new uint256[](stakedDevs.length());
        address dev;

        for (uint256 i = 0; i < stakedDevs.length(); i++) {
            dev = stakedDevs.at(i);
            shares[i] = AspectaDevPool(devPools[dev]).balanceOf(user);
        }
        return (stakedDevs.values(), shares);
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
        uint256[] memory totalDevRewards = new uint256[](devs.length);
        uint256[] memory totalStakeRewards = new uint256[](devs.length);

        require(
            devs.length <= 20,
            "AspectaDevPoolFactory: Exceeds limit of 20 addresses"
        );
        for (uint32 i = 0; i < devs.length; i++) {
            if (devPools[devs[i]] == address(0)) {
                totalDevRewards[i] = 0;
                totalStakeRewards[i] = 0;
                continue;
            }

            (totalDevRewards[i], totalStakeRewards[i]) = IAspectaDevPool(
                devPools[devs[i]]
            ).getTotalAccRewards();
        }

        return (totalDevRewards, totalStakeRewards);
    }

    /**
     * @dev Get dev pool
     * @return pool Dev pool address
     */
    function getPool(address dev) external view returns (address) {
        return devPools[dev];
    }

    /**
     * @dev Get all staked devs for a staker
     * @return pools All dev pool addresses
     */
    function getStakedDevs(
        address user
    ) external view returns (address[] memory) {
        return stakedDevSet[user].values();
    }

    // --------------------- beacon ---------------------
    /**
     * @notice Get the implementation address of the beacon
     * @return Implementation address
     */
    function getImplementation() public view returns (address) {
        return beacon.implementation();
    }

    /**
     * @notice Get the beacon address
     * @return Beacon address
     */
    function getBeacon() public view returns (address) {
        return address(beacon);
    }

    // --------------------- setters ---------------------
    /**
     * @notice Set the default inflation rate
     * @param _defaultInflationRate New default inflation rate
     */
    function setDefaultInflationRate(
        uint256 _defaultInflationRate
    ) public onlyOwner returns (uint256) {
        defaultInflationRate = _defaultInflationRate;
        return defaultInflationRate;
    }
}
