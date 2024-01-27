// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Utils
import {SoladyTest} from "solady/test/utils/SoladyTest.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {LibPRNG} from "@solady/utils/LibPRNG.sol";
import {Merkle} from "murky/src/Merkle.sol";

// Mocks
import {Token} from "test/mocks/Token.sol";

// Tested contracts
import {AirdropClaimMapping} from "src/AirdropClaimMapping.sol";
import {AirdropClaimMerkle} from "src/AirdropClaimMerkle.sol";
import {AirdropClaimSignature} from "src/AirdropClaimSignature.sol";
import {Airdrop as AirdropWentokens} from "src/AirdropWentokens.sol";
import {GasliteDrop} from "src/GasliteDrop.sol";
import {BytecodeDrop} from "src/BytecodeDrop.sol";

// mark _randomData as virtual
// maybe will need return additional parameters (like with ERC721, ERC1155) so inherited will retrieve only part of the return data
// can actually keep all contracts but rename Token => ERC20Token, ERC721Token, etc
// same for merkle data
// same for signature data
// Actually can only implement the tests in inherited contracts, and maybe override (e.g. ERC721, even if might call super to get some of the data)

/// @dev Test with n recipients
/// Note: This is an extremely simplistic approach to measuring gas costs.
/// This, for instance is a much better approach by emo.eth:
/// https://github.com/emo-eth/forge-gas-metering

/// @dev Customize the amount of recipients to test with
uint256 constant NUM_RECIPIENTS = 1000;

contract Benchmarks_Base is SoladyTest, StdCheats {
    using LibPRNG for LibPRNG.PRNG;

    Token token;
    Merkle m;

    AirdropClaimMapping airdropClaimMapping;
    AirdropClaimMerkle airdropClaimMerkle;
    AirdropClaimSignature airdropClaimSignature;
    AirdropWentokens airdropWentokens;
    GasliteDrop gasliteDrop;
    BytecodeDrop bytecodeDrop;

    address[] RECIPIENTS = new address[](NUM_RECIPIENTS);
    uint256[] AMOUNTS = new uint256[](NUM_RECIPIENTS);
    uint256 TOTAL_AMOUNT;

    // Merkle
    bytes32 ROOT;
    bytes32[] DATA = new bytes32[](NUM_RECIPIENTS);

    // Signature
    address SIGNER;
    uint256 SIGNER_KEY;

    /* -------------------------------------------------------------------------- */
    /*                                    SETUP                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Should be called at the beginning of each test to take advantage of the random
    /// calldata passed for fuzzing, to generate random data
    function setup() internal {
        // Generate random airdrop data
        (RECIPIENTS, AMOUNTS, TOTAL_AMOUNT) = _randomData();
        // Generate Merkle data
        m = new Merkle();
        (ROOT, DATA) = _generateMerkleData(RECIPIENTS, AMOUNTS);
        // Generate signature data
        (SIGNER, SIGNER_KEY) = _randomSigner();

        // Deploy contracts
        token = new Token(TOTAL_AMOUNT);
        airdropClaimMapping = new AirdropClaimMapping(address(token));
        airdropClaimMerkle = new AirdropClaimMerkle(address(token), ROOT);
        airdropClaimSignature = new AirdropClaimSignature(address(token), SIGNER);
        airdropWentokens = new AirdropWentokens();
        gasliteDrop = new GasliteDrop();
        bytecodeDrop = new BytecodeDrop();
    }

    /* -------------------------------------------------------------------------- */
    /*                                    UTILS                                   */
    /* -------------------------------------------------------------------------- */

    /// Note: We're using Solady `LibPRNG` to generate random addresses over a simple
    /// vm.addr(i) for more realistic gas costs
    function _randomData()
        internal
        virtual
        returns (address[] memory recipients, uint256[] memory amounts, uint256 totalAmount)
    {
        // Initialize PRNG
        LibPRNG.PRNG memory prng = LibPRNG.PRNG(_random());
        // Initialize arrays
        recipients = new address[](NUM_RECIPIENTS);
        amounts = new uint256[](NUM_RECIPIENTS);

        // Populate arrays with random data
        for (uint256 i = 0; i < NUM_RECIPIENTS; i++) {
            recipients[i] = address(uint160(prng.next() % 2 ** 160));
            // Bound amount: 1e10 <= amount <= 1e19
            amounts[i] = _bound(prng.next(), 1e10, 1e19);
            totalAmount += amounts[i];
        }
    }

    function _generateMerkleData(address[] memory recipients, uint256[] memory amounts)
        internal
        view
        virtual
        returns (bytes32 root, bytes32[] memory data)
    {
        // Populate data array with leaf hashes
        data = new bytes32[](NUM_RECIPIENTS);
        for (uint256 i = 0; i < NUM_RECIPIENTS; i++) {
            data[i] = keccak256(abi.encodePacked(recipients[i], amounts[i]));
        }

        // Get the Merkle root
        root = m.getRoot(data);
    }
}
