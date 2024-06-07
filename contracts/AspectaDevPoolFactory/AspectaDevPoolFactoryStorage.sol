// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "./IAspectaDevPoolFactory.sol";

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

    /// @notice Contract address of the DEV token
    address public aspectaDevToken;

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
