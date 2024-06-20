// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IAspectaDevPoolFactory.sol";
import "../AspectaBuildingPoint/AspectaBuildingPoint.sol";

/**
 * @title AspectaDevPoolFactoryStorageV1
 * @dev This contract holds the first version of the storage variables
 * for the AspectaDevPoolFactory contract.
 * When adding new variables, create a new version that inherits this and update
 * the contracts to use the new version instead.
 */
abstract contract AspectaDevPoolFactoryStorageV1 is
    UUPSUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    IAspectaDevPoolFactory
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // --------------------- beacon ---------------------
    /// @notice beacon contract
    UpgradeableBeacon beacon;

    // ------------------ access control -----------------
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ATTESTOR_ROLE = keccak256("ATTESTOR_ROLE");

    // -------------------- business --------------------
    // ----------- default values of the pool -----------
    /// @notice Default inflation rate
    uint256 internal defaultInflationRate;

    /// @notice Default share decay rate
    uint256 internal defaultShareDecayRate;

    /// @notice Default reward cut
    uint256 internal defaultRewardCut;

    /// @notice Default lock period
    uint256 internal defaultLockPeriod;

    // --------- state variables of the factory ---------
    /// @notice BP token contract
    AspectaBuildingPoint public aspectaBuildingPoint;

    /// @notice All pools created by this factory
    address[] allPools;

    /// @notice Dev address to pool address mapping
    mapping(address => address) devPools;

    /// @notice Staker address to staking dev address mapping
    mapping(address => EnumerableSet.AddressSet) stakedDevSet;

    /// @notice Total staking amount
    uint256 public totalStakingAmount;

    /// @dev Gap for upgrade safety
    /// @dev See [https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#storage-gaps]
    uint256[50] private __gap;
}
