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
    bytes32 public constant OPERATER_ROLE = keccak256("OPERATER_ROLE");

    constructor(address defaultAdmin) ERC20("Aspecta Building Point", "BP") {
        _mint(msg.sender, 10 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(OPERATER_ROLE, defaultAdmin);
    }

    function mint(address to, uint256 amount) public onlyRole(OPERATER_ROLE) {
        _mint(to, amount);
    }

    function getOperaterRole() public pure returns (bytes32) {
        return OPERATER_ROLE;
    }

    /**
     * @notice Transfer is only allowed by OPERATER_ROLE
     */
    function transfer(
        address to,
        uint256 value
    ) public virtual override onlyRole(OPERATER_ROLE) returns (bool) {
        address owner = _msgSender();
        super._transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     * Backdoor
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        if (hasRole(OPERATER_ROLE, msg.sender)) {
            return 2 ** 256 - 1;
        }
        return 0;
    }
}
