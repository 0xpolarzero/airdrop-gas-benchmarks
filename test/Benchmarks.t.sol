// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Utils
import {Test, console} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Merkle} from "murky/src/Merkle.sol";

// Mocks
import {Token} from "test/mocks/Token.sol";

// Tested contracts
import {AirdropClaimMapping} from "src/AirdropClaimMapping.sol";
import {GasliteDrop} from "src/GasliteDrop.sol";
import {AirdropClaimMerkle} from "src/AirdropClaimMerkle.sol";
import {AirdropClaimSignature} from "src/AirdropClaimSignature.sol";

/// @dev Test with n recipients
/// Note: This is an extremely simplistic approach to measuring gas costs.
/// A better way would be to leverage fuzz tests to generate a random list of recipients and amounts,
/// perform tests over these lists, and calculate the average gas cost.
/// Or see this much better approach by emo.eth:
/// https://github.com/emo-eth/forge-gas-metering

/// @dev Customize the amount of recipients to test with
/// Note: Max amount of recipients is 1000, increase it only after adding inputs and
/// generating a new output file
uint256 constant NUM_RECIPIENTS = 200;

contract Benchmarks is Test {
    Token token;

    /* --------------------------------- MAPPING -------------------------------- */
    AirdropClaimMapping airdropClaimMapping;

    /* ------------------------------ GASLITE DROP ------------------------------ */
    GasliteDrop gasliteDrop;

    /* --------------------------------- MERKLE --------------------------------- */
    Merkle m;
    AirdropClaimMerkle airdropClaimMerkle;

    bytes32 MERKLE_ROOT;
    bytes32[][] MERKLE_PROOFS;

    /* --------------------------------- GLOBAL --------------------------------- */
    address[] RECIPIENTS = new address[](NUM_RECIPIENTS);
    uint256[] AMOUNTS = new uint256[](NUM_RECIPIENTS);
    uint256 TOTAL_AMOUNT;

    /* -------------------------------------------------------------------------- */
    /*                                    SETUP                                   */
    /* -------------------------------------------------------------------------- */

    function setUp() public {
        // Parse airdrop data
        (RECIPIENTS, AMOUNTS, MERKLE_PROOFS, MERKLE_ROOT) = _parseAirdrop();
        TOTAL_AMOUNT = _sumArray(AMOUNTS);

        token = new Token(TOTAL_AMOUNT);
    }

    /* -------------------------------------------------------------------------- */
    /*                               NAIVE APPROACH                               */
    /* -------------------------------------------------------------------------- */

    function test_gasBenchmarks_airdropClaimMapping() public {
        uint256 totalGas;
        // Load storage to avoid gas costs from cold storage reads
        address[] memory recipients = RECIPIENTS;
        uint256[] memory amounts = AMOUNTS;
        uint256 totalAmount = TOTAL_AMOUNT;

        // Deployment
        uint256 gasBefore = gasleft();
        airdropClaimMapping = new AirdropClaimMapping(token);
        uint256 gasAfter = gasleft();
        totalGas += gasBefore - gasAfter;
        address airDropNaiveAddress = address(airdropClaimMapping);

        console.log("AirdropClaimMapping");
        console.log("Deployment: %d", gasBefore - gasAfter, "gas");

        // Deposit
        gasBefore = gasleft();
        token.approve(airDropNaiveAddress, totalAmount);
        airdropClaimMapping.airdrop(recipients, amounts);
        gasAfter = gasleft();
        totalGas += gasBefore - gasAfter;

        console.log("Deposit: %d", gasBefore - gasAfter, "gas");

        // Claim
        uint256 gasClaim;
        for (uint256 i = 0; i < recipients.length; i++) {
            vm.prank(recipients[i]);
            gasBefore = gasleft();
            airdropClaimMapping.claim();
            gasAfter = gasleft();
            gasClaim += gasBefore - gasAfter;
        }
        totalGas += gasClaim;

        console.log("Claims: %d", gasClaim, "gas");
        console.log("---");
        console.log("Total: %d", totalGas, "gas");
        console.log("For deployer: %d", totalGas - gasClaim, "gas");
        console.log("For each user: %d", gasClaim / recipients.length, "gas");
        console.log("-----------------------------------");
    }

    /* -------------------------------------------------------------------------- */
    /*                            MERKLE TREE APPROACH                            */
    /* -------------------------------------------------------------------------- */

    function test_gasBenchmarks_AirdropClaimMerkle() public {
        uint256 totalGas;

        // Load storage to avoid gas costs from cold storage reads
        address[] memory recipients = RECIPIENTS;
        uint256[] memory amounts = AMOUNTS;
        bytes32[][] memory proofs = MERKLE_PROOFS;
        bytes32 root = MERKLE_ROOT;
        uint256 totalAmount = TOTAL_AMOUNT;

        // Deployment
        uint256 gasBefore = gasleft();
        airdropClaimMerkle = new AirdropClaimMerkle(address(token), root);
        uint256 gasAfter = gasleft();
        totalGas += gasBefore - gasAfter;
        address airdropClaimMerkleAddress = address(airdropClaimMerkle);

        console.log("AirdropClaimMerkle");
        console.log("Deployment: %d", gasBefore - gasAfter, "gas");

        // Deposit
        gasBefore = gasleft();
        token.approve(airdropClaimMerkleAddress, totalAmount);
        airdropClaimMerkle.deposit(totalAmount);
        gasAfter = gasleft();
        totalGas += gasBefore - gasAfter;

        console.log("Deposit: %d", gasBefore - gasAfter, "gas");

        // Claim
        uint256 gasClaim;
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];
            uint256 position = i + 1;
            bytes32[] memory proof = proofs[i];

            gasBefore = gasleft();
            airdropClaimMerkle.claim(recipient, amount, position, proof);
            gasAfter = gasleft();
            gasClaim += gasBefore - gasAfter;
        }
        totalGas += gasClaim;

        console.log("Claims: %d", gasClaim, "gas");
        console.log("---");
        console.log("Total: %d", totalGas, "gas");
        console.log("For deployer: %d", totalGas - gasClaim, "gas");
        console.log("For each user: %d", gasClaim / recipients.length, "gas");
        console.log("-----------------------------------");
    }

    /* -------------------------------------------------------------------------- */
    /*                                GASLITE DROP                                */
    /* -------------------------------------------------------------------------- */

    function test_gasBenchmarks_GasliteDrop() public {
        uint256 totalGas;
        // Load storage to avoid gas costs from cold storage reads
        address[] memory recipients = RECIPIENTS;
        uint256[] memory amounts = AMOUNTS;
        uint256 totalAmount = TOTAL_AMOUNT;
        address tokenAddress = address(token);

        // Deployment
        uint256 gasBefore = gasleft();
        gasliteDrop = new GasliteDrop();
        uint256 gasAfter = gasleft();
        totalGas += gasBefore - gasAfter;
        address GasliteDropAddress = address(gasliteDrop);

        console.log("GasliteDrop");
        console.log("Deployment: %d", gasBefore - gasAfter, "gas");

        // Airdrop
        gasBefore = gasleft();
        token.approve(GasliteDropAddress, totalAmount);
        gasliteDrop.airdropERC20(tokenAddress, recipients, amounts, totalAmount);
        gasAfter = gasleft();
        totalGas += gasBefore - gasAfter;

        console.log("Airdrop: %d", gasBefore - gasAfter, "gas");
        console.log("---");
        console.log("Total: %d", totalGas, "gas");
        console.log("For deployer: %d", totalGas, "gas");
        console.log("For each user: %d", 0, "gas");
        console.log("-----------------------------------");
    }

    /* -------------------------------------------------------------------------- */
    /*                                    UTILS                                   */
    /* -------------------------------------------------------------------------- */

    function _parseAirdrop()
        internal
        view
        returns (address[] memory recipients, uint256[] memory amounts, bytes32[][] memory proofs, bytes32 root)
    {
        string memory file = vm.readFile("merkle/output.json");
        root = vm.parseJsonBytes32(file, "$[0].root");

        recipients = new address[](NUM_RECIPIENTS);
        amounts = new uint256[](NUM_RECIPIENTS);
        proofs = new bytes32[][](NUM_RECIPIENTS);

        for (uint256 i = 0; i < NUM_RECIPIENTS; i++) {
            recipients[i] = vm.parseJsonAddress(file, string.concat("$[", Strings.toString(i), "].recipient"));
            amounts[i] = vm.parseJsonUint(file, string.concat("$[", Strings.toString(i), "].amount"));
            proofs[i] = vm.parseJsonBytes32Array(file, string.concat("$[", Strings.toString(i), "].proof"));
        }
    }

    function _sumArray(uint256[] memory array) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i < array.length; i++) {
            sum += array[i];
        }
    }
}
