// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "./AspectaDevPoolFactoryStorage.sol";
import "../AspectaDevPool/AspectaDevPool.sol";
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
        uint256 _defaultShareCoeff,
        uint256 _defaultInflationRate,
        uint256 _defaultMaxPPM
    ) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        beacon = new UpgradeableBeacon(poolLogic, msg.sender);

        aspectaBuildingPoint = AspectaBuildingPoint(aspTokenAddress);
        defaultShareCoeff = _defaultShareCoeff;
        defaultInflationRate = _defaultInflationRate;
        defaultMaxPPM = _defaultMaxPPM;
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
    function createPool(address dev) internal returns (address) {
        require(
            devPools[dev] == address(0),
            "AspectaDevPoolFactory: Pool already exists for dev"
        );
        // TODO: AspectaDevPool initialize may take more parameters
        BeaconProxy poolProxy = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                AspectaDevPool(address(0)).initialize.selector,
                dev,
                defaultShareCoeff,
                defaultInflationRate,
                defaultMaxPPM
            )
        );
        devPools[dev] = address(poolProxy);
        allPools.push(address(poolProxy));

        // Grant operator role to dev
        aspectaBuildingPoint.grantRole(
            aspectaBuildingPoint.getRoleOperater(),
            address(poolProxy)
        );

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
            devPoolAddr = createPool(dev);
        } else {
            devPoolAddr = devPools[dev];
        }

        // Stake tokens in dev pool
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
            aspectaBuildingPoint.balanceOf(devPoolAddr),
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
            aspectaBuildingPoint.balanceOf(devPools[dev]),
            devPool.totalSupply()
        );
    }

    /**
     * @dev Claim rewards for a dev/staker with all staked devs
     */
    function claimRewards() external override {
        EnumerableSet.AddressSet memory stakedDevs = stakedDevSet[msg.sender];
        uint256 claimedAmount;
        for (uint256 i = 0; i < stakedDevs.length(); i++) {
            address dev = stakedDevs.at(i);
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
        address dev;
        uint256 claimedAmount;
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
        EnumerableSet.AddressSet memory stakedDevs = stakedDevSet[user];
        uint256 totalUnclaimedRewards = 0;
        address dev;
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
        EnumerableSet.AddressSet memory stakedDevs = stakedDevSet[user];
        uint256[] memory shares = new uint256[](stakedDevs.length());
        address dev;

        for (uint256 i = 0; i < stakedDevs.length(); i++) {
            dev = stakedDevs.at(i);
            shares[i] = AspectaDevPool(devPools[dev]).getShares(user);
        }
        return (stakedDevs.values(), shares);
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
     * @notice Set the default share coefficient
     * @param _defaultShareCoeff New default share coefficient
     */
    function setDefaultShareCoeff(
        uint256 _defaultShareCoeff
    ) public onlyOwner returns (uint256) {
        defaultShareCoeff = _defaultShareCoeff;
        return defaultShareCoeff;
    }

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
     * @notice Set the default maxPPM
     * @param _defaultMaxPPM New default maxPPM
     */
    function setDefaultMaxPPM(
        uint256 _defaultMaxPPM
    ) public onlyOwner returns (uint256) {
        defaultMaxPPM = _defaultMaxPPM;
        return defaultMaxPPM;
    }
}
