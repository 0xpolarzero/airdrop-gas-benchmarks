// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import {Token} from "test/mocks/Token.sol";

import {AirdropNaive} from "src/AirdropNaive.sol";
import {GasliteDrop} from "src/GasliteDrop.sol";
import {MerkleClaimERC20} from "src/MerkleClaimERC20.sol";

/// @dev Test with 100 recipients
/// Note: This is an extremely simplistic approach to measuring gas costs.
/// A better way would be to leverage fuzz tests to generate a random list of recipients and amounts,
/// perform tests over these lists, and calculate the average gas cost.
/// Or see this much better approach by emo.eth:
/// https://github.com/emo-eth/forge-gas-metering

contract Benchmarks is Test {
    Token token;
    AirdropNaive airdropNaive;
    GasliteDrop gasliteDrop;
    MerkleClaimERC20 merkleClaimERC20;

    address[] RECIPIENTS;
    uint256[] AMOUNTS;
    uint256 TOTAL_AMOUNT;
    uint256 TOKEN_DECIMALS = 18;

    function setUp() public {
        // Parse airdrop data
        (RECIPIENTS, AMOUNTS) = _parseAirdrop();
        TOTAL_AMOUNT = _sumArray(AMOUNTS);

        token = new Token(TOTAL_AMOUNT);
    }

    /* -------------------------------------------------------------------------- */
    /*                               NAIVE APPROACH                               */
    /* -------------------------------------------------------------------------- */

    function test_gasBenchmarks_airdropNaive() public {
        uint256 totalGas;
        // Load storage to avoid gas costs from cold storage reads
        address[] memory recipients = RECIPIENTS;
        uint256[] memory amounts = AMOUNTS;
        uint256 totalAmount = TOTAL_AMOUNT;

        // Deployment
        uint256 gasBefore = gasleft();
        airdropNaive = new AirdropNaive(token);
        uint256 gasAfter = gasleft();
        totalGas += gasBefore - gasAfter;
        address airDropNaiveAddress = address(airdropNaive);

        console.log("AirdropNaive");
        console.log("Deployment: %d", gasBefore - gasAfter, "gas");

        // Deposit
        gasBefore = gasleft();
        token.approve(airDropNaiveAddress, totalAmount);
        airdropNaive.airdrop(recipients, amounts);
        gasAfter = gasleft();
        totalGas += gasBefore - gasAfter;

        console.log("Deposit: %d", gasBefore - gasAfter, "gas");

        // Claim
        uint256 gasClaim;
        for (uint256 i = 0; i < recipients.length; i++) {
            vm.prank(recipients[i]);
            gasBefore = gasleft();
            airdropNaive.claim();
            gasAfter = gasleft();
            gasClaim += gasBefore - gasAfter;
        }
        totalGas += gasClaim;

        console.log("Claims: %d", gasClaim, "gas");
        console.log("---");
        console.log("Total: %d", totalGas, "gas");
        console.log("For deployer: %d", totalGas - gasClaim, "gas");
        console.log("For a user: %d", gasClaim / recipients.length, "gas");
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
    /*                             MERKLE CLAIM ERC20                             */
    /* -------------------------------------------------------------------------- */

    function test_gasBenchmarks_MerkleClaimERC20() public {
        bytes32 root = _parseMerkle();
        uint256 totalGas;

        // Load storage to avoid gas costs from cold storage reads
        address[] memory recipients = RECIPIENTS;
        uint256[] memory amounts = AMOUNTS;
        uint256 totalAmount = TOTAL_AMOUNT;

        // Deployment
        uint256 gasBefore = gasleft();
        merkleClaimERC20 = new MerkleClaimERC20(token, root);
        uint256 gasAfter = gasleft();
        totalGas += gasBefore - gasAfter;
        address merkleClaimERC20Address = address(merkleClaimERC20);

        console.log("MerkleClaimERC20");
        console.log("Deployment: %d", gasBefore - gasAfter, "gas");

        // Deposit
        gasBefore = gasleft();
        token.approve(merkleClaimERC20Address, totalAmount);
        merkleClaimERC20.deposit(totalAmount);
        gasAfter = gasleft();
        totalGas += gasBefore - gasAfter;

        console.log("Deposit: %d", gasBefore - gasAfter, "gas");

        // ! See in token.ts how generated; might need to do with Buffer
        // ! as it's not just what I do below but more

        // Claim
        uint256 gasClaim;
        for (uint256 i = 0; i < recipients.length; i++) {
            // Generate merkle proof
            bytes32 leaf = keccak256(abi.encodePacked(recipients[i], amounts[i]));
            bytes32[] memory proof = new bytes32[](1);
            proof[0] = leaf;

            gasBefore = gasleft();
            merkleClaimERC20.claim(recipients[i], amounts[i], proof);
            gasAfter = gasleft();
            gasClaim += gasBefore - gasAfter;
        }
        totalGas += gasClaim;

        console.log("Claims: %d", gasClaim, "gas");
        console.log("---");
        console.log("Total: %d", totalGas, "gas");
        console.log("For deployer: %d", totalGas - gasClaim, "gas");
        console.log("For a user: %d", gasClaim / recipients.length, "gas");
        console.log("-----------------------------------");
    }

    /* -------------------------------------------------------------------------- */
    /*                                    UTILS                                   */
    /* -------------------------------------------------------------------------- */

    function _parseAirdrop() internal view returns (address[] memory recipients, uint256[] memory amounts) {
        string memory file = vm.readFile("data/airdrop.json");
        recipients = vm.parseJsonAddressArray(file, "$.recipients");
        amounts = vm.parseJsonUintArray(file, "$.amounts");

        amounts = _scaleToTokenDecimals(amounts);
    }

    function _scaleToTokenDecimals(uint256[] memory array) internal view returns (uint256[] memory scaled) {
        scaled = new uint256[](array.length);
        for (uint256 i = 0; i < array.length; i++) {
            scaled[i] = array[i] * (10 ** TOKEN_DECIMALS);
        }
    }

    function _sumArray(uint256[] memory array) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i < array.length; i++) {
            sum += array[i];
        }
    }

    function _parseMerkle() internal view returns (bytes32 root) {
        string memory file = vm.readFile("data/merkle.json");
        root = vm.parseJsonBytes32(file, "$.root");
    }
}
