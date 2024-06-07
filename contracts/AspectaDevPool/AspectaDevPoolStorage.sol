// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {IAspectaDevPool} from "./IAspectaDevPool.sol";

/**
 * @title AspectaDevPoolStorageV1
 * @dev This contract holds the first version of the storage variables
 * for the AspectaDevPool contract.
 * When adding new variables, create a new version that inherits this and update
 * the contracts to use the new version instead.
 */
abstract contract AspectaDevPoolStorageV1 is
    ERC20Upgradeable,
    OwnableUpgradeable,
    IAspectaDevPool
{
    address public developer;

    uint256 public totalStake;

    uint256 internal devRewardCheckpoint;

    uint256 internal lastRewardedBlockNum;

    uint256 public shareCoeff;

    uint256 internal inflationRate;

    uint256 public buildingProgress;

    uint256 internal maxPPM;

    mapping(address => StakerState) public stakerStates;

    uint256[50] private __gap;
}
