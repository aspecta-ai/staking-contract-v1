// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title AspectaBuildingPoint
 * @dev ERC20 token contract for AspectaBuildingPoint
 */
contract AspectaBuildingPoint is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    constructor(address defaultAdmin) ERC20("Aspecta Building Point", "BP") {
        _mint(msg.sender, 10 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(OPERATOR_ROLE, defaultAdmin);
        _setRoleAdmin(OPERATOR_ROLE, FACTORY_ROLE);
    }

    function mint(address to, uint256 amount) public onlyRole(OPERATOR_ROLE) {
        _mint(to, amount);
    }

    function getOperatorRole() public pure returns (bytes32) {
        return OPERATOR_ROLE;
    }

    function getFactoryRole() public pure returns (bytes32) {
        return FACTORY_ROLE;
    }

    /**
     * @notice Transfer is only allowed by OPERATOR_ROLE
     */
    function transfer(
        address to,
        uint256 value
    ) public virtual override onlyRole(OPERATOR_ROLE) returns (bool) {
        address owner = _msgSender();
        super._transfer(owner, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override onlyRole(OPERATOR_ROLE) returns (bool) {
        //address spender = _msgSender();
        //_spendAllowance(from, spender, value);
        super._transfer(from, to, value);
        return true;
    }
}
