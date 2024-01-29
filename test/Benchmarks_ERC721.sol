// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Benchmarks.base.sol";
import {IAirdropERC721} from "src/thirdweb/deps/IAirdropERC721.sol";

// See Benchmarks.base.sol for more info and to modify the amount of recipients to test with

// 1. MAPPING APPROACH (claim)
// 2. MERKLE TREE APPROACH (claim)
// 3. SIGNATURE APPROACH (claim)
// 4. GASLITE DROP (airdrop)
// 5. THIRDWEB AIRDROP (airdrop)
// 6. THIRDWEB AIRDROP (claim)

contract Benchmarks_ERC721 is Benchmarks_Base {
    /* -------------------------------------------------------------------------- */
    /*                                    SETUP                                   */
    /* -------------------------------------------------------------------------- */

    function _setType() internal override {
        testType = TEST_TYPE.ERC721;
    }

    /* -------------------------------------------------------------------------- */
    /*                             1. MAPPING APPROACH                            */
    /* -------------------------------------------------------------------------- */

    function test_ERC721_AirdropClaimMapping(uint256) public {
        setup();

        // Airdrop
        erc721.setApprovalForAll(address(airdropClaimMapping), true);
        airdropClaimMapping.airdropERC721(RECIPIENTS, TOKEN_IDS_ERC721);

        // Claim
        for (uint256 i = 0; i < RECIPIENTS.length; i++) {
            vm.prank(RECIPIENTS[i]);
            airdropClaimMapping.claimERC721();
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                           2. MERKLE TREE APPROACH                          */
    /* -------------------------------------------------------------------------- */

    function test_ERC721_AirdropClaimMerkle(uint256) public {
        setup();

        // Deposit
        for (uint256 i = 0; i < TOKEN_IDS_ERC721.length; i++) {
            erc721.transferFrom(address(this), address(airdropClaimMerkle), TOKEN_IDS_ERC721[i]);
        }

        // Claim
        for (uint256 i = 0; i < RECIPIENTS.length; i++) {
            bytes32[] memory proof = m.getProof(DATA_ERC721, i);
            // prank doesn't really matter as anyone can claim with a valid proof, since tokens are sent to the recipient
            vm.prank(RECIPIENTS[i]);
            airdropClaimMerkle.claimERC721(RECIPIENTS[i], TOKEN_IDS_ERC721[i], proof);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                            3. SIGNATURE APPROACH                           */
    /* -------------------------------------------------------------------------- */

    function test_ERC721_AirdropClaimSignature(uint256) public {
        setup();

        // Deposit
        for (uint256 i = 0; i < TOKEN_IDS_ERC721.length; i++) {
            erc721.transferFrom(address(this), address(airdropClaimSignature), TOKEN_IDS_ERC721[i]);
        }

        // Claim
        for (uint256 i = 0; i < RECIPIENTS.length; i++) {
            bytes memory signature = _sign(keccak256(abi.encodePacked(RECIPIENTS[i], TOKEN_IDS_ERC721[i])));
            // Same here with prank, some can claim on behalf of the recipient (but tokens are sent to the recipient)
            vm.prank(RECIPIENTS[i]);
            airdropClaimSignature.claimERC721(RECIPIENTS[i], TOKEN_IDS_ERC721[i], signature);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                               4. GASLITE DROP                              */
    /* -------------------------------------------------------------------------- */

    function test_ERC721_GasliteDrop(uint256) public {
        setup();

        // Airdrop
        erc721.setApprovalForAll(address(gasliteDrop), true);
        gasliteDrop.airdropERC721(address(erc721), RECIPIENTS, TOKEN_IDS_ERC721);
    }

    /* -------------------------------------------------------------------------- */
    /*                             5. THIRDWEB AIRDROP                            */
    /* -------------------------------------------------------------------------- */

    function test_ERC721_AirdropERC721Thirdweb(uint256) public {
        setup();

        // Airdrop
        erc721.setApprovalForAll(address(thirdweb_airdropERC721), true);
        thirdweb_airdropERC721.airdropERC721(
            address(erc721), address(this), _toAirdropContent(RECIPIENTS, TOKEN_IDS_ERC721)
        );
    }

    function _toAirdropContent(address[] memory _recipients, uint256[] memory _tokenIds)
        internal
        pure
        returns (IAirdropERC721.AirdropContent[] memory contents)
    {
        contents = new IAirdropERC721.AirdropContent[](_recipients.length);
        for (uint256 i = 0; i < _recipients.length; i++) {
            contents[i] = IAirdropERC721.AirdropContent({recipient: _recipients[i], tokenId: _tokenIds[i]});
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                             6. THIRDWEB CLAIM                              */
    /* -------------------------------------------------------------------------- */

    function test_ERC721_AirdropERC721ClaimableThirdweb(uint256) public {
        setup();

        // Airdrop
        erc721.setApprovalForAll(address(thirdweb_airdropERC721Claimable), true);

        // Claim
        for (uint256 i = 0; i < RECIPIENTS.length; i++) {
            bytes32[] memory proof = m.getProof(DATA_ERC721_THIRDWEB, i);
            vm.prank(RECIPIENTS[i]);
            // You can't claim a specific token with this contract, but you can get a specific quantity
            // which is basically a mint
            thirdweb_airdropERC721Claimable.claim(RECIPIENTS[i], 1, proof, 1);
        }
    }
}
