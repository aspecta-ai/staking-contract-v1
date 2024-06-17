// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./IAspectaDevPool.sol";

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
    address public factory;

    address public developer;

    address public aspectaToken;

    uint256 public inflationRate;

    uint256 public shareDecayRate;

    uint256 public rewardCut;

    uint256 public defaultLockPeriod;

    uint256 public buildIndex;

    uint256 public totalAccReward;

    uint256 internal rewardPerShare;

    uint256 internal lastRewardedBlockNum;

    uint256 internal devLastReward;

    uint256 internal shareCoeff;

    mapping(address => StakerState) public stakerStates;

    uint256[50] private __gap;
}
