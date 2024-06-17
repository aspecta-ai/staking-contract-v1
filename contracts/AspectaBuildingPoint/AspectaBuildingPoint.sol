// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./AspectaBuildingPointStorage.sol";

/**
 * @title AspectaBuildingPoint
 * @dev ERC20 token contract for AspectaBuildingPoint
 */
contract AspectaBuildingPoint is Initializable, AspectaBuildingPointStorageV1 {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin) public initializer {
        __ERC20_init("Aspecta Building Point", "BP");
        __AccessControl_init();
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

    function batchMint(
        address[] calldata toList,
        uint256[] calldata amountList
    ) public onlyRole(OPERATOR_ROLE) {
        require(
            toList.length <= 100,
            "AspectaBuildingPoint: Exceeds limit of 100 addresses"
        );
        require(
            toList.length == amountList.length,
            "AspectaBuildingPoint: Invalid input"
        );

        for (uint32 i = 0; i < toList.length; i++) {
            _mint(toList[i], amountList[i]);
        }
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

    /**
     * @dev Upgrade the contract
     * @param newImplementation New implementation address
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
