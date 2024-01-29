// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC1155} from "@solady/tokens/ERC1155.sol";

/// @dev An ultra-minimalistic ERC1155 token implementation.
contract Mock_ERC1155 is ERC1155 {
    constructor(uint256[] memory _initialAmounts) {
        for (uint256 i = 0; i < _initialAmounts.length; i++) {
            _mint(msg.sender, i, _initialAmounts[i], "");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                  METADATA                                  */
    /* -------------------------------------------------------------------------- */

    function uri(uint256) public pure override returns (string memory) {
        return "https://example.com";
    }
}
