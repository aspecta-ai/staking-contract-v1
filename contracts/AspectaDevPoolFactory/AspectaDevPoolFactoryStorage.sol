// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
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
    IAspectaDevPoolFactory
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // --------------------- beacon ---------------------
    /// @notice beacon contract
    UpgradeableBeacon beacon;

    // -------------------- business --------------------
    // ----------- default values of the pool -----------
    /// @notice Default share coefficient
    uint256 public defaultShareCoeff;

    /// @notice Default inflation rate
    uint256 internal defaultInflationRate;

    /// @notice Default max PPM
    uint256 internal defaultMaxPPM;

    // --------- state variables of the factory ---------
    /// @notice BP token contract
    AspectaBuildingPoint public aspectaBuildingPoint;

    /// @notice All pools created by this factory
    address[] allPools;

    /// @notice Dev address to pool address mapping
    mapping(address => address) devPools;

    /// @notice Staker address to staking dev address mapping
    mapping(address => EnumerableSet.AddressSet) stakedDevSet;

    /// @dev Gap for upgrade safety
    /// @dev See [https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#storage-gaps]
    uint256[50] private __gap;
}
