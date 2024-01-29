// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Benchmarks.base.sol";

// See Benchmarks.base.sol for more info and to modify the amount of recipients to test with

// 1. MAPPING APPROACH (claim)
// 2. MERKLE TREE APPROACH (claim)
// 3. SIGNATURE APPROACH (claim)
// 4. GASLITE DROP (airdrop)
// 5. THIRDWEB AIRDROP (airdrop)
// 6. THIRDWEB AIRDROP (claim)

contract Benchmarks_ERC1155 is Benchmarks_Base {
    /* -------------------------------------------------------------------------- */
    /*                                    SETUP                                   */
    /* -------------------------------------------------------------------------- */

    function _setType() internal override {
        testType = TEST_TYPE.ERC1155;
    }

    /* -------------------------------------------------------------------------- */
    /*                             1. MAPPING APPROACH                            */
    /* -------------------------------------------------------------------------- */

    function test_ERC1155_AirdropClaimMapping(uint256) public {
        setup();
    }

    /* -------------------------------------------------------------------------- */
    /*                           2. MERKLE TREE APPROACH                          */
    /* -------------------------------------------------------------------------- */

    function test_ERC1155_AirdropClaimMerkle(uint256) public {
        setup();
    }

    /* -------------------------------------------------------------------------- */
    /*                            3. SIGNATURE APPROACH                           */
    /* -------------------------------------------------------------------------- */

    function test_ERC1155_AirdropClaimSignature(uint256) public {
        setup();
    }

    /* -------------------------------------------------------------------------- */
    /*                               4. GASLITE DROP                              */
    /* -------------------------------------------------------------------------- */

    function test_ERC1155_GasliteDrop1155() public {
        setup();

        // Approval
        erc1155.setApprovalForAll(address(gasliteDrop1155), true);

        // We can actually take advantage of the structure of the parameters, as it can take
        // multiple recipients for a single similar amount, which is very likely to happen in
        // the case of airdrops.
        (GasliteDrop1155.AirdropToken[] memory airdropTokens) =
            _storeGasliteDrop1155AirdropContent(RECIPIENTS, AMOUNTS, TOKEN_IDS_ERC1155);

        // Airdrop
        gasliteDrop1155.airdropERC1155(address(erc1155), airdropTokens);
    }

    /// Note: The following is highly inefficient, but we don't really care since this is just
    /// for aggregating data prior to the call & measurement
    // Helper mapping for easier aggregation (push)
    mapping(uint256 tokenId => GasliteDrop1155.AirdropTokenAmount[] tokenAmounts) airdropTokenAmounts;

    // Helper function to format the airdrop content into GasliteDrop1155.AirdropToken[]
    function _storeGasliteDrop1155AirdropContent(
        address[] memory _recipients,
        uint256[] memory _amounts,
        uint256[] memory _tokenIds
    ) internal returns (GasliteDrop1155.AirdropToken[] memory airdropTokens) {
        // Find the amount of unique amounts for each tokenId & aggregate the recipients who have the same amount
        uint256[] memory uniqueAmountsForTokenId = new uint256[](NUM_ERC1155_IDS);
        for (uint256 i = 0; i < _recipients.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < i; j++) {
                if (_amounts[i] == _amounts[j] && _tokenIds[i] == _tokenIds[j]) {
                    found = true;
                    break;
                }
            }
            if (!found) uniqueAmountsForTokenId[_tokenIds[i]]++;
        }

        // For each tokenId
        for (uint256 i = 0; i < NUM_ERC1155_IDS; i++) {
            uint256 currentAmountIndex = 0;
            // For each recipient
            for (uint256 j = 0; j < _recipients.length; j++) {
                // If the tokenId matches
                if (_tokenIds[j] == i) {
                    bool found = false;

                    // Find if the amount already exists
                    for (uint256 k = 0; k < currentAmountIndex; k++) {
                        // If it does, push the recipient to the array
                        if (_amounts[j] == airdropTokenAmounts[i][k].amount) {
                            airdropTokenAmounts[i][k].recipients.push(_recipients[j]);
                            found = true;
                            break;
                        }
                    }

                    // If it doesn't, create a new entry
                    if (!found) {
                        airdropTokenAmounts[i].push(
                            GasliteDrop1155.AirdropTokenAmount({amount: _amounts[j], recipients: new address[](0)})
                        );
                        airdropTokenAmounts[i][currentAmountIndex].recipients.push(_recipients[j]);
                        currentAmountIndex++;
                    }
                }
            }
        }

        // Create the airdropTokens array
        airdropTokens = new GasliteDrop1155.AirdropToken[](NUM_ERC1155_IDS);
        for (uint256 i = 0; i < NUM_ERC1155_IDS; i++) {
            airdropTokens[i] = GasliteDrop1155.AirdropToken({tokenId: i, airdropAmounts: airdropTokenAmounts[i]});
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                             5. THIRDWEB AIRDROP                            */
    /* -------------------------------------------------------------------------- */

    function test_ERC1155_AirdropERC1155Thirdweb(uint256) public {
        setup();
    }

    // function _toAirdropContent(address[] memory _recipients, uint256[] memory _tokenIds)
    //     internal
    //     pure
    //     returns (IAirdropERC721.AirdropContent[] memory contents)
    // {
    //     contents = new IAirdropERC721.AirdropContent[](_recipients.length);
    //     for (uint256 i = 0; i < _recipients.length; i++) {
    //         contents[i] = IAirdropERC721.AirdropContent({recipient: _recipients[i], tokenId: _tokenIds[i]});
    //     }
    // }

    /* -------------------------------------------------------------------------- */
    /*                             6. THIRDWEB CLAIM                              */
    /* -------------------------------------------------------------------------- */

    function test_ERC1155_AirdropERC1155ClaimableThirdweb(uint256) public {
        setup();
    }

    /* -------------------------------------------------------------------------- */
    /*                                   ERC1155                                  */
    /* -------------------------------------------------------------------------- */

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
