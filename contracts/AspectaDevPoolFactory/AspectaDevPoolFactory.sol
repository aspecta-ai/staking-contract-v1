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

    function initialize(
        address initialOwner,
        address aspTokenAddress,
        address poolLogic,
        uint256 _defaultInflationRate,
        uint256 _defaultShareDecayRate,
        uint256 _defaultRewardCut,
        uint256 _defaultLockPeriod
    ) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(OPERATOR_ROLE, initialOwner);

        beacon = new UpgradeableBeacon(poolLogic, msg.sender);

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
        IAspectaDevPool(devPoolAddr).stake(amount);
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
        IAspectaDevPool(devPools[dev]).withdraw();

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
            IAspectaDevPool(devPools[dev]).claimStakeReward();
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
            IAspectaDevPool(devPools[dev]).claimStakeReward();
        }
    }

    /**
     * @dev Claim rewards for a dev
     */
    function claimDevReward() external override {
        IAspectaDevPool(devPools[msg.sender]).claimDevReward();
    }

    /**
     * @dev Update the build index
     * @param _buildIndex New build index
     */
    function updateBuildIndex(
        address dev,
        uint256 _buildIndex
    ) external override onlyOwner {
        require(
            devPools[dev] != address(0),
            "AspectaDevPoolFactory: Pool does not exist for dev"
        );
        IAspectaDevPool(devPools[dev]).updateBuildIndex(_buildIndex);
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
    function getTotalClaimableDevReward()
        external
        view
        override
        returns (uint256)
    {
        return IAspectaDevPool(devPools[msg.sender]).getClaimableDevReward();
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
