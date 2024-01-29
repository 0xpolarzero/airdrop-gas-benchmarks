// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Test Utils
import {SoladyTest} from "solady/test/utils/SoladyTest.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {console} from "forge-std/console.sol";

// Libs
import {LibPRNG} from "@solady/utils/LibPRNG.sol";
import {LibClone} from "@solady/utils/LibClone.sol";
import {Merkle} from "murky/src/Merkle.sol";

// Mocks
import {Mock_ERC20} from "test/mocks/Mock_ERC20.sol";
import {Mock_ERC721} from "test/mocks/Mock_ERC721.sol";
import {Mock_ERC1155} from "test/mocks/Mock_ERC1155.sol";

// Tested contracts
import {AirdropClaimMapping} from "src/AirdropClaimMapping.sol";
import {AirdropClaimMerkle} from "src/AirdropClaimMerkle.sol";
import {AirdropClaimSignature} from "src/AirdropClaimSignature.sol";
import {BytecodeDrop} from "src/BytecodeDrop.sol";
// wentokens
import {Airdrop as Wentokens_Airdrop} from "src/Wentokens.sol";
// Gaslite
import {GasliteDrop} from "src/GasliteDrop.sol";
import {GasliteDrop1155} from "src/GasliteDrop1155.sol";
// Thirdweb
import {AirdropERC20 as Thirdweb_AirdropERC20} from "src/thirdweb/AirdropERC20.sol";
import {AirdropERC20Claimable as Thirdweb_AirdropERC20Claimable} from "src/thirdweb/AirdropERC20Claimable.sol";
import {AirdropERC721 as Thirdweb_AirdropERC721} from "src/thirdweb/AirdropERC721.sol";
import {AirdropERC721Claimable as Thirdweb_AirdropERC721Claimable} from "src/thirdweb/AirdropERC721Claimable.sol";
import {AirdropERC1155 as Thirdweb_AirdropERC1155} from "src/thirdweb/AirdropERC1155.sol";
import {AirdropERC1155Claimable as Thirdweb_AirdropERC1155Claimable} from "src/thirdweb/AirdropERC1155Claimable.sol";

/// @dev Test with n recipients
/// Note: This is an extremely simplistic approach to measuring gas costs.
/// This, for instance is a much better approach by emo.eth:
/// https://github.com/emo-eth/forge-gas-metering
/// But this won't (as of 2024-01) allow for multiple calls to be measured in a single test
/// A better way right now would be to use Hardhat's gas reporter; which you can actually find in this repo.

/// @dev Customize the amount of recipients to test with
uint256 constant NUM_RECIPIENTS = 1000;
/// @dev Customize the amount of different ERC1155 ids to distribute
uint256 constant NUM_ERC1155_IDS = 20;

abstract contract Benchmarks_Base is SoladyTest, StdCheats {
    using LibPRNG for LibPRNG.PRNG;

    Mock_ERC20 erc20;
    Mock_ERC721 erc721;
    Mock_ERC1155 erc1155;
    Merkle m;

    AirdropClaimMapping airdropClaimMapping;
    AirdropClaimMerkle airdropClaimMerkle;
    AirdropClaimSignature airdropClaimSignature;
    Wentokens_Airdrop wentokens_airdrop;
    GasliteDrop gasliteDrop;
    GasliteDrop1155 gasliteDrop1155;
    BytecodeDrop bytecodeDrop;
    Thirdweb_AirdropERC20 thirdweb_airdropERC20;
    Thirdweb_AirdropERC20Claimable thirdweb_airdropERC20Claimable;
    Thirdweb_AirdropERC721 thirdweb_airdropERC721;
    Thirdweb_AirdropERC721Claimable thirdweb_airdropERC721Claimable;
    Thirdweb_AirdropERC1155 thirdweb_airdropERC1155;
    Thirdweb_AirdropERC1155Claimable thirdweb_airdropERC1155Claimable;

    // ERC20, ERC721, ERC1155
    address[] RECIPIENTS = new address[](NUM_RECIPIENTS);
    // ERC20, ERC1155
    uint256[] AMOUNTS = new uint256[](NUM_RECIPIENTS);
    // ERC20
    uint256 TOTAL_AMOUNT_ERC20;
    // ERC721
    uint256[] TOKEN_IDS_ERC721 = new uint256[](NUM_RECIPIENTS);
    // ERC1155
    uint256[] TOKEN_IDS_ERC1155 = new uint256[](NUM_RECIPIENTS);
    uint256[] TOTAL_AMOUNTS_ERC1155 = new uint256[](NUM_ERC1155_IDS);

    // Merkle
    bytes32 ROOT_ERC20;
    bytes32 ROOT_ERC721;
    bytes32 ROOT_ERC1155;
    bytes32[] DATA_ERC20 = new bytes32[](NUM_RECIPIENTS);
    bytes32[] DATA_ERC721 = new bytes32[](NUM_RECIPIENTS);
    bytes32[] DATA_ERC1155 = new bytes32[](NUM_RECIPIENTS);
    // We need special variables for Thirdweb because it doesn't actually transfer specific tokens, but only specific quantities
    bytes32 ROOT_ERC721_THIRDWEB;
    bytes32[] DATA_ERC721_THIRDWEB = new bytes32[](NUM_RECIPIENTS);
    // Thirdweb also takes a series of roots for ERC1155 (one for each id)
    bytes32[] ROOT_ERC1155_THIRDWEB = new bytes32[](NUM_ERC1155_IDS);
    bytes32[][] DATA_ERC1155_THIRDWEB = new bytes32[][](NUM_ERC1155_IDS);

    // Signature
    address SIGNER;
    uint256 SIGNER_KEY;

    enum TEST_TYPE {
        ETH,
        ERC20,
        ERC721,
        ERC1155
    }

    TEST_TYPE testType;

    /* -------------------------------------------------------------------------- */
    /*                                    SETUP                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Should be called at the beginning of each test to take advantage of the random
    /// calldata passed for fuzzing, to generate random data
    function setup() internal {
        _setType();
        _generate();
        _deploy();
    }

    /// @dev This needs to be implemented in each contract
    function _setType() internal virtual;

    function _generate() internal virtual {
        // Generate random airdrop data
        (RECIPIENTS, AMOUNTS, TOTAL_AMOUNT_ERC20, TOKEN_IDS_ERC721, TOKEN_IDS_ERC1155, TOTAL_AMOUNTS_ERC1155) =
            _randomData();
        // Generate Merkle data
        m = new Merkle();
        (ROOT_ERC20, ROOT_ERC721, ROOT_ERC1155, DATA_ERC20, DATA_ERC721, DATA_ERC1155) =
            _generateMerkleData(RECIPIENTS, AMOUNTS, TOKEN_IDS_ERC721, TOKEN_IDS_ERC1155);
        // Generate Thirdweb Merkle data that doesn't fit the way above
        (ROOT_ERC721_THIRDWEB, ROOT_ERC1155_THIRDWEB, DATA_ERC721_THIRDWEB, DATA_ERC1155_THIRDWEB) =
            _thirdweb_generateMerkleData(RECIPIENTS, AMOUNTS, TOKEN_IDS_ERC1155);
        // Generate signature data
        (SIGNER, SIGNER_KEY) = _randomSigner();
    }

    function _deploy() internal virtual {
        // Deploy contracts
        erc20 = new Mock_ERC20(TOTAL_AMOUNT_ERC20);
        erc721 = new Mock_ERC721(TOKEN_IDS_ERC721);

        uint256[] memory ids = new uint256[](NUM_ERC1155_IDS);
        for (uint256 i = 0; i < NUM_ERC1155_IDS; i++) {
            ids[i] = i;
        }
        erc1155 = new Mock_ERC1155(ids, TOTAL_AMOUNTS_ERC1155);

        airdropClaimMapping = new AirdropClaimMapping(erc20, erc721, erc1155);
        airdropClaimMerkle = new AirdropClaimMerkle(erc20, erc721, erc1155, ROOT_ERC20, ROOT_ERC721, ROOT_ERC1155);
        airdropClaimSignature = new AirdropClaimSignature(erc20, erc721, erc1155, SIGNER);
        wentokens_airdrop = new Wentokens_Airdrop();
        gasliteDrop = new GasliteDrop();
        gasliteDrop1155 = new GasliteDrop1155();
        bytecodeDrop = new BytecodeDrop();

        _deployThirdwebProxiesAndInit(ids);
    }

    function _deployThirdwebProxiesAndInit(uint256[] memory _ids) internal {
        // Deploy proxies
        thirdweb_airdropERC20 = Thirdweb_AirdropERC20(LibClone.deployERC1967(address(new Thirdweb_AirdropERC20())));
        thirdweb_airdropERC20Claimable =
            Thirdweb_AirdropERC20Claimable(LibClone.deployERC1967(address(new Thirdweb_AirdropERC20Claimable())));
        thirdweb_airdropERC721 = Thirdweb_AirdropERC721(LibClone.deployERC1967(address(new Thirdweb_AirdropERC721())));
        thirdweb_airdropERC721Claimable =
            Thirdweb_AirdropERC721Claimable(LibClone.deployERC1967(address(new Thirdweb_AirdropERC721Claimable())));
        thirdweb_airdropERC1155 =
            Thirdweb_AirdropERC1155(LibClone.deployERC1967(address(new Thirdweb_AirdropERC1155())));
        thirdweb_airdropERC1155Claimable =
            Thirdweb_AirdropERC1155Claimable(LibClone.deployERC1967(address(new Thirdweb_AirdropERC1155Claimable())));

        // Initialize
        thirdweb_airdropERC20.initialize(address(this), "https://example.com", new address[](0));
        thirdweb_airdropERC20Claimable.initialize(
            new address[](0), address(this), address(erc20), TOTAL_AMOUNT_ERC20, 0, 0, ROOT_ERC20
        );
        thirdweb_airdropERC721.initialize(address(this), "https://example.com", new address[](0));
        thirdweb_airdropERC721Claimable.initialize(
            new address[](0), address(this), address(erc721), TOKEN_IDS_ERC721, 0, 0, ROOT_ERC721_THIRDWEB
        );
        thirdweb_airdropERC1155.initialize(address(this), "https://example.com", new address[](0));
        thirdweb_airdropERC1155Claimable.initialize(
            new address[](0),
            address(this),
            address(erc1155),
            _ids,
            TOTAL_AMOUNTS_ERC1155,
            0,
            new uint256[](NUM_ERC1155_IDS),
            ROOT_ERC1155_THIRDWEB
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                                    UTILS                                   */
    /* -------------------------------------------------------------------------- */

    /// Note: We're using Solady `LibPRNG` to generate random addresses over a simple
    /// vm.addr(i) for more realistic gas costs
    function _randomData()
        internal
        virtual
        returns (
            address[] memory recipients,
            uint256[] memory amounts,
            uint256 totalAmount_erc20,
            uint256[] memory tokenIds_erc721,
            uint256[] memory tokenIds_erc1155,
            uint256[] memory totalAmounts_erc1155
        )
    {
        // Initialize PRNG
        LibPRNG.PRNG memory prng = LibPRNG.PRNG(_random());
        // Initialize arrays
        recipients = new address[](NUM_RECIPIENTS);
        amounts = new uint256[](NUM_RECIPIENTS);
        tokenIds_erc721 = new uint256[](NUM_RECIPIENTS);
        tokenIds_erc1155 = new uint256[](NUM_RECIPIENTS);
        totalAmounts_erc1155 = new uint256[](NUM_ERC1155_IDS);

        // Populate arrays with random data
        for (uint256 i = 0; i < NUM_RECIPIENTS; i++) {
            // ERC20, ERC721, ERC1155
            recipients[i] = address(uint160(prng.next() % 2 ** 160));

            // ERC20, ERC1155
            // Get a random or similar amount (more realistic as multiple recipients would often receive the same amount)
            // Solady's `_random()` would do this, but with not enough similarity
            amounts[i] = _getRandomOrSimilarAmount(prng, amounts, i);

            // ERC20
            totalAmount_erc20 += amounts[i];

            // ERC721
            tokenIds_erc721[i] = i;

            // ERC1155
            // Bound id: 0 <= id <= NUM_ERC1155_IDS
            tokenIds_erc1155[i] = prng.next() % NUM_ERC1155_IDS;
            totalAmounts_erc1155[tokenIds_erc1155[i]] += amounts[i];
        }
    }

    function _getRandomOrSimilarAmount(LibPRNG.PRNG memory _prng, uint256[] memory _amounts, uint256 _index)
        internal
        virtual
        returns (uint256 amount)
    {
        // Bound amount: 1e10 <= amount <= 1e19
        amount = _bound(_prng.next(), 1e10, 1e19);

        // 60% chance of returning an amount already used
        // This will produce realistic results as this is associated with the {1/NUM_TOKEN_IDS}
        // probability of getting the same id as the copied amount
        // e.g. with 1,000 recipients and 20 ids, we get an average of 14% of similar amounts on the same id
        if (_index > 0 && _prng.next() % 100 < 60) {
            amount = _amounts[_prng.next() % _index];
        }
    }

    function _generateMerkleData(
        address[] memory _recipients,
        uint256[] memory _amounts,
        uint256[] memory _tokenIds_erc721,
        uint256[] memory _tokenIds_erc1155
    )
        internal
        view
        virtual
        returns (
            bytes32 root_erc20,
            bytes32 root_erc721,
            bytes32 root_erc1155,
            bytes32[] memory data_erc20,
            bytes32[] memory data_erc721,
            bytes32[] memory data_erc1155
        )
    {
        data_erc20 = new bytes32[](NUM_RECIPIENTS);
        data_erc721 = new bytes32[](NUM_RECIPIENTS);
        data_erc1155 = new bytes32[](NUM_RECIPIENTS);

        // Populate data array with leaf hashes
        for (uint256 i = 0; i < NUM_RECIPIENTS; i++) {
            data_erc20[i] = keccak256(abi.encodePacked(_recipients[i], _amounts[i]));
            data_erc721[i] = keccak256(abi.encodePacked(_recipients[i], _tokenIds_erc721[i]));
            data_erc1155[i] = keccak256(abi.encodePacked(_recipients[i], _tokenIds_erc1155[i], _amounts[i]));
        }

        // Get the Merkle root
        root_erc20 = m.getRoot(data_erc20);
        root_erc721 = m.getRoot(data_erc721);
        root_erc1155 = m.getRoot(data_erc1155);
    }

    function _thirdweb_generateMerkleData(
        address[] memory _recipients,
        uint256[] memory _amounts,
        uint256[] memory _tokenIds
    )
        internal
        view
        virtual
        returns (
            bytes32 root_erc721_thirdweb,
            bytes32[] memory root_erc1155_thirdweb,
            bytes32[] memory data_erc721_thirdweb,
            bytes32[][] memory data_erc1155_thirdweb
        )
    {
        data_erc721_thirdweb = new bytes32[](NUM_RECIPIENTS);
        data_erc1155_thirdweb = new bytes32[][](NUM_ERC1155_IDS);

        // Populate data array with leaf hashes
        for (uint256 i = 0; i < NUM_RECIPIENTS; i++) {
            data_erc721_thirdweb[i] = keccak256(abi.encodePacked(_recipients[i], uint256(1)));
        }
        // Same for each Thirdweb ERC1155 data array
        for (uint256 i = 0; i < NUM_ERC1155_IDS; i++) {
            data_erc1155_thirdweb[i] = new bytes32[](NUM_RECIPIENTS);
            for (uint256 j = 0; j < NUM_RECIPIENTS; j++) {
                if (_tokenIds[j] == i) {
                    data_erc1155_thirdweb[i][j] = keccak256(abi.encodePacked(_recipients[j], _amounts[j]));
                }
            }
        }

        // Get the Merkle root
        root_erc721_thirdweb = m.getRoot(data_erc721_thirdweb);

        root_erc1155_thirdweb = new bytes32[](NUM_ERC1155_IDS);
        for (uint256 i = 0; i < NUM_ERC1155_IDS; i++) {
            root_erc1155_thirdweb[i] = m.getRoot(data_erc1155_thirdweb[i]);
        }
    }
}
