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

// Tested contracts
import {AirdropClaimMapping} from "src/AirdropClaimMapping.sol";
import {AirdropClaimMerkle} from "src/AirdropClaimMerkle.sol";
import {AirdropClaimSignature} from "src/AirdropClaimSignature.sol";
import {BytecodeDrop} from "src/BytecodeDrop.sol";
// wentokens
import {Airdrop as Wentokens_Airdrop} from "src/Wentokens.sol";
// Gaslite
import {GasliteDrop} from "src/GasliteDrop.sol";
// Thirdweb
import {AirdropERC20 as Thirdweb_AirdropERC20} from "src/thirdweb/AirdropERC20.sol";
import {AirdropERC20Claimable as Thirdweb_AirdropERC20Claimable} from "src/thirdweb/AirdropERC20Claimable.sol";

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

abstract contract Benchmarks_Base is SoladyTest, StdCheats {
    using LibPRNG for LibPRNG.PRNG;

    Mock_ERC20 erc20;
    Mock_ERC721 erc721;
    Merkle m;

    AirdropClaimMapping airdropClaimMapping;
    AirdropClaimMerkle airdropClaimMerkle;
    AirdropClaimSignature airdropClaimSignature;
    Wentokens_Airdrop wentokens_airdrop;
    GasliteDrop gasliteDrop;
    BytecodeDrop bytecodeDrop;
    Thirdweb_AirdropERC20 thirdweb_airdropERC20;
    Thirdweb_AirdropERC20Claimable thirdweb_airdropERC20Claimable;

    // ERC20, ERC721
    address[] RECIPIENTS = new address[](NUM_RECIPIENTS);
    // ERC20
    uint256[] AMOUNTS = new uint256[](NUM_RECIPIENTS);
    uint256 TOTAL_AMOUNT;
    // ERC721
    uint256[] TOKEN_IDS = new uint256[](NUM_RECIPIENTS);

    // Merkle
    bytes32 ROOT_ERC20;
    bytes32 ROOT_ERC721;
    bytes32[] DATA_ERC20 = new bytes32[](NUM_RECIPIENTS);
    bytes32[] DATA_ERC721 = new bytes32[](NUM_RECIPIENTS);

    // Signature
    address SIGNER;
    uint256 SIGNER_KEY;

    enum TEST_TYPE {
        ETH,
        ERC20,
        ERC721
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
        (RECIPIENTS, AMOUNTS, TOTAL_AMOUNT, TOKEN_IDS) = _randomData();
        // Generate Merkle data
        m = new Merkle();
        (ROOT_ERC20, ROOT_ERC721, DATA_ERC20, DATA_ERC721) = _generateMerkleData(RECIPIENTS, AMOUNTS, TOKEN_IDS);
        // Generate signature data
        (SIGNER, SIGNER_KEY) = _randomSigner();
    }

    function _deploy() internal virtual {
        // Deploy contracts
        erc20 = new Mock_ERC20(TOTAL_AMOUNT);
        erc721 = new Mock_ERC721(TOKEN_IDS);
        airdropClaimMapping = new AirdropClaimMapping(erc20, erc721);
        airdropClaimMerkle = new AirdropClaimMerkle(erc20, erc721, ROOT_ERC20, ROOT_ERC721);
        airdropClaimSignature = new AirdropClaimSignature(erc20, erc721, SIGNER);
        wentokens_airdrop = new Wentokens_Airdrop();
        gasliteDrop = new GasliteDrop();
        bytecodeDrop = new BytecodeDrop();

        Thirdweb_AirdropERC20 thirdweb_airdropERC20Impl = new Thirdweb_AirdropERC20();
        Thirdweb_AirdropERC20Claimable thirdweb_airdropERC20ClaimableImpl = new Thirdweb_AirdropERC20Claimable();
        _deployProxiesAndInit(address(thirdweb_airdropERC20Impl), address(thirdweb_airdropERC20ClaimableImpl));
    }

    function _deployProxiesAndInit(address _airdropERC20Impl, address _airdropERC20ClaimableImpl) internal {
        // Deploy proxies
        thirdweb_airdropERC20 = Thirdweb_AirdropERC20(LibClone.deployERC1967(_airdropERC20Impl));
        thirdweb_airdropERC20Claimable =
            Thirdweb_AirdropERC20Claimable(LibClone.deployERC1967(_airdropERC20ClaimableImpl));

        // Initialize
        thirdweb_airdropERC20.initialize(address(this), "https://example.com", new address[](0));
        thirdweb_airdropERC20Claimable.initialize(
            new address[](0), address(this), address(erc20), TOTAL_AMOUNT, 0, 0, ROOT_ERC20
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
        returns (address[] memory recipients, uint256[] memory amounts, uint256 totalAmount, uint256[] memory tokenIds)
    {
        // Initialize PRNG
        LibPRNG.PRNG memory prng = LibPRNG.PRNG(_random());
        // Initialize arrays
        recipients = new address[](NUM_RECIPIENTS);
        amounts = new uint256[](NUM_RECIPIENTS);
        tokenIds = new uint256[](NUM_RECIPIENTS);

        // Populate arrays with random data
        for (uint256 i = 0; i < NUM_RECIPIENTS; i++) {
            recipients[i] = address(uint160(prng.next() % 2 ** 160));

            // Bound amount: 1e10 <= amount <= 1e19
            amounts[i] = _bound(prng.next(), 1e10, 1e19);
            totalAmount += amounts[i];

            tokenIds[i] = i;
        }
    }

    function _generateMerkleData(address[] memory recipients, uint256[] memory amounts, uint256[] memory tokenIds)
        internal
        view
        virtual
        returns (bytes32 root_erc20, bytes32 root_erc721, bytes32[] memory data_erc20, bytes32[] memory data_erc721)
    {
        data_erc20 = new bytes32[](NUM_RECIPIENTS);
        data_erc721 = new bytes32[](NUM_RECIPIENTS);

        // Populate data array with leaf hashes
        for (uint256 i = 0; i < NUM_RECIPIENTS; i++) {
            data_erc20[i] = keccak256(abi.encodePacked(recipients[i], amounts[i]));
            data_erc721[i] = keccak256(abi.encodePacked(recipients[i], tokenIds[i]));
        }

        // Get the Merkle root
        root_erc20 = m.getRoot(data_erc20);
        root_erc721 = m.getRoot(data_erc721);
    }
}
