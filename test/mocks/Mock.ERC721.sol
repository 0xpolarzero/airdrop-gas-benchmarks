// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "@solady/tokens/ERC721.sol";

/// @dev An ultra-minimalistic ERC721 token implementation.
contract MockERC721 is ERC721 {
    constructor(uint256[] memory _tokenIds) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _mint(msg.sender, _tokenIds[i]);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                  METADATA                                  */
    /* -------------------------------------------------------------------------- */

    function name() public pure override returns (string memory) {
        return "MockERC721";
    }

    function symbol() public pure override returns (string memory) {
        return "M721";
    }

    function tokenURI(uint256 id) public pure override returns (string memory) {
        return string(abi.encodePacked("https://example.com/", id));
    }
}
