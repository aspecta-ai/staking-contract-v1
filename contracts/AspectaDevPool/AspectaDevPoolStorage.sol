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

    address public aspectaToken;

    uint256 internal inflationRate;

    uint256 internal shareDecayRate;

    uint256 internal rewardCut;

    uint256 public buildIndex;

    uint256 public rewardPerShare;

    uint256 internal lastRewardedBlockNum;

    uint256 internal devLastRewardPerShare;

    uint256 public shareCoeff;

    uint256 internal maxPPM;

    mapping(address => StakerState) public stakerStates;

    uint256[50] private __gap;
}
