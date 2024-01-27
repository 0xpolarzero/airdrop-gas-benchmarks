// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@solady/tokens/ERC20.sol";

/// @dev An ultra-minimalistic ERC20 token implementation.
contract Token is ERC20 {
    constructor(uint256 initialAmount) {
        _mint(msg.sender, initialAmount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  METADATA                                  */
    /* -------------------------------------------------------------------------- */

    function name() public pure override returns (string memory) {
        return "Token";
    }

    function symbol() public pure override returns (string memory) {
        return "TKN";
    }
}
