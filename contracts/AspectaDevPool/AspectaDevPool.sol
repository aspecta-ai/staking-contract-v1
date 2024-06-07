// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IAspectaDevPool} from "./IAspectaDevPool.sol";
import {AspectaDevPoolStorageV1} from "./AspectaDevPoolStorage.sol";

/**
 * @title AspectaDevPool
 * @dev Contract for dev pools
 */
contract AspectaDevPool is
    Initializable,
    AspectaDevPoolStorageV1,
    IAspectaDevPool
{
    function initialize(
        address _developer,
        uint256 _shareCoeff,
        uint256 _inflationRate,
        uint256 _maxPPM
    ) public initializer {
        __ERC20_init("Aspecta Dev Pool", "ADP");
        __Ownable_init(msg.sender);
        developer = _developer;
        shareCoeff = _shareCoeff;
        inflationRate = _inflationRate;
        maxPPM = _maxPPM;
    }
}
