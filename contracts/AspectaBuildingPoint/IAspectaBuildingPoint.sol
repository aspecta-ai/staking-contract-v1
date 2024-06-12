// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.25;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";

/**
 * @title AspectaBuildingPoint
 * @dev ERC20 token contract for AspectaBuildingPoint
 */
interface IAspectaBuildingPoint {
    function balanceOf(address _owner) external view returns (uint256);

    function mint(address _to, uint256 _amount) external;

    function getOperaterRole() external view returns (bytes32);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);
}
