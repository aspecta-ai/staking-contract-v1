// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.25;

import "./AspectaBuildingPoint.sol";

library AspectaBuildingPointUtils {
    /**
     * @dev Pull tokens from an address to this contract.
     * @param _token Token to transfer
     * @param _from Address sending the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pullTokens(
        AspectaBuildingPoint _token,
        address _from,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(
                _token.transferFrom(_from, address(this), _amount),
                "!transfer"
            );
        }
    }

    /**
     * @dev Push tokens from this contract to a receiving address.
     * @param _token Token to transfer
     * @param _to Address receiving the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pushTokens(
        AspectaBuildingPoint _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(_token.transfer(_to, _amount), "!transfer");
        }
    }

    /**
     * @dev Burn tokens held by this contract.
     * @param _token Token to burn
     * @param _amount Amount of tokens to burn
     */
    function burnTokens(AspectaBuildingPoint _token, uint256 _amount) internal {
        if (_amount > 0) {
            _token.burn(_amount);
        }
    }
}
