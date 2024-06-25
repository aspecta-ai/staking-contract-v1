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

    function _getPool(address dev) internal returns (address) {
        // If pool does not exist, create one
        if (devPools[dev] == address(0)) {
            return _createPool(dev);
        } else {
            return devPools[dev];
        }
    }

    /**
     * @dev Stake tokens for a dev
     * @param dev Dev address
     * @param amount Amount to stake
     */
    function stake(address dev, uint256 amount) external override {
        address devPoolAddr = _getPool(dev);

        // Stake tokens in dev pool
        IAspectaDevPool(devPoolAddr).stake(msg.sender, amount);
        stakingDevSet[msg.sender].add(dev);
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
        stakingDevSet[msg.sender].remove(dev);
    }

    /**
     * @dev Claim rewards for a staker with all staked devs
     */
    function claimStakeReward() external override {
        EnumerableSet.AddressSet storage stakingDevs = stakingDevSet[msg.sender];
        address dev;
        for (uint256 i = 0; i < stakingDevs.length(); i++) {
            dev = stakingDevs.at(i);
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
        address devPoolAddr = _getPool(dev);
        IAspectaDevPool(devPoolAddr).updateBuildIndex(buildIndex);
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
     * @dev Get dev pool
     * @return Address of the dev pool contract
     */
    function getPool(address dev) external view returns (address) {
        return devPools[dev];
    }

    /**
     * @dev Get all staked devs for a staker
     * @return Addresses of the staking devs
     */
    function getStakingDevs(
        address user
    ) external view returns (address[] memory) {
        return stakingDevSet[user].values();
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

    /**
     * @notice Set default lock period
     * @param _defaultLockPeriod New default lock period
     */
    function setDefaultLockPeriod(
        uint256 _defaultLockPeriod
    ) external override onlyOwner {
        defaultLockPeriod = _defaultLockPeriod;
        for (uint256 i = 0; i < allPools.length; i++) {
            IAspectaDevPool(allPools[i]).setDefaultLockPeriod(
                _defaultLockPeriod
            );
        }
    }
}
