// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Benchmarks.base.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// See Benchmarks.base.sol for more info and to modify the amount of recipients to test with

// 1. MAPPING APPROACH
// 2. MERKLE TREE APPROACH
// 3. SIGNATURE APPROACH
// 4. DISPERSE APP
// 5. WENTOKENS
// 6. GASLITE DROP
// 7. BYTECODE DROP

contract Benchmarks_ERC20 is Benchmarks_Base {
    /* -------------------------------------------------------------------------- */
    /*                                    SETUP                                   */
    /* -------------------------------------------------------------------------- */

    function _setType() internal override {
        testType = TEST_TYPE.ERC20;
    }

    /* -------------------------------------------------------------------------- */
    /*                             1. MAPPING APPROACH                            */
    /* -------------------------------------------------------------------------- */

    function test_ERC20_AirdropClaimMapping(uint256) public {
        setup();

        // Deposit and set mapping
        erc20.approve((address(airdropClaimMapping)), TOTAL_AMOUNT);
        airdropClaimMapping.airdropERC20(RECIPIENTS, AMOUNTS);

        // Claim
        for (uint256 i = 0; i < RECIPIENTS.length; i++) {
            vm.prank(RECIPIENTS[i]);
            airdropClaimMapping.claimERC20();
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                           2. MERKLE TREE APPROACH                          */
    /* -------------------------------------------------------------------------- */

    function test_ERC20_AirdropClaimMerkle(uint256) public {
        setup();

        // Deposit
        erc20.transfer(address(airdropClaimMerkle), TOTAL_AMOUNT);

        // Claim
        for (uint256 i = 0; i < RECIPIENTS.length; i++) {
            bytes32[] memory proof = m.getProof(DATA_ERC20, i);
            // prank doesn't really matter as anyone can claim with a valid proof, since tokens are sent to the recipient
            vm.prank(RECIPIENTS[i]);
            airdropClaimMerkle.claimERC20(RECIPIENTS[i], AMOUNTS[i], proof);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                            3. SIGNATURE APPROACH                           */
    /* -------------------------------------------------------------------------- */

    function test_ERC20_AirdropClaimSignature(uint256) public {
        setup();

        // Deposit
        erc20.transfer(address(airdropClaimSignature), TOTAL_AMOUNT);

        // Claim
        for (uint256 i = 0; i < RECIPIENTS.length; i++) {
            bytes32 messageHash = keccak256(abi.encodePacked(RECIPIENTS[i], AMOUNTS[i]));
            bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_KEY, prefixedHash);
            bytes memory signature = abi.encodePacked(r, s, v);

            // Same here with prank, some can claim on behalf of the recipient (but tokens are sent to the recipient)
            vm.prank(RECIPIENTS[i]);
            airdropClaimSignature.claimERC20(RECIPIENTS[i], AMOUNTS[i], signature);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                               4. DISPERSE APP                              */
    /* -------------------------------------------------------------------------- */

    function test_ERC20_Disperse_disperseToken(uint256) public {
        setup();
        // Deploy Disperse with cheatcode because of the pragma solidity ^0.4.25
        address deployed = deployCode("Disperse.sol");
        erc20.approve(deployed, TOTAL_AMOUNT);

        // Airdrop ("disperse")
        (bool success,) = deployed.call(
            abi.encodeWithSignature("disperseToken(address,address[],uint256[])", address(erc20), RECIPIENTS, AMOUNTS)
        );
        if (!success) revert("test_ERC20_Disperse_FAILED");
    }

    function test_ERC20_Disperse_disperseTokenSimple(uint256) public {
        setup();
        // Deploy Disperse with cheatcode because of the pragma solidity ^0.4.25
        address deployed = deployCode("Disperse.sol");
        erc20.approve(deployed, TOTAL_AMOUNT);

        // Airdrop ("disperse")

        // Airclaim (`disperseTokenSimple`)
        (bool success,) = deployed.call(
            abi.encodeWithSignature(
                "disperseTokenSimple(address,address[],uint256[])", address(erc20), RECIPIENTS, AMOUNTS
            )
        );
        if (!success) revert("test_ERC20_Disperse_FAILED");
    }

    /* -------------------------------------------------------------------------- */
    /*                                5. WENTOKENS                                */
    /* -------------------------------------------------------------------------- */

    function test_ERC20_AirdropWentokens(uint256) public {
        setup();

        // Airdrop
        erc20.approve(address(airdropWentokens), TOTAL_AMOUNT);
        airdropWentokens.airdropERC20(IERC20(address(erc20)), RECIPIENTS, AMOUNTS, TOTAL_AMOUNT);
    }

    /* -------------------------------------------------------------------------- */
    /*                               6. GASLITE DROP                              */
    /* -------------------------------------------------------------------------- */

    function test_ERC20_GasliteDrop(uint256) public {
        setup();

        // Airdrop
        erc20.approve(address(gasliteDrop), TOTAL_AMOUNT);
        gasliteDrop.airdropERC20(address(erc20), RECIPIENTS, AMOUNTS, TOTAL_AMOUNT);
    }

    /* -------------------------------------------------------------------------- */
    /*                              7. BYTECODE DROP                              */
    /* -------------------------------------------------------------------------- */

    function test_ERC20_BytecodeDrop(uint256) public {
        setup();

        address deployed = deployCode("BytecodeDrop.sol");

        // Airdrop
        erc20.approve(deployed, TOTAL_AMOUNT);
        // bytecodeDrop.airdropERC20(address(erc20), RECIPIENTS, AMOUNTS, TOTAL_AMOUNT);
        (bool success,) = deployed.call(
            abi.encodeWithSignature(
                "airdropERC20(address,address[],uint256[],uint256)", address(erc20), RECIPIENTS, AMOUNTS, TOTAL_AMOUNT
            )
        );
        if (!success) revert("test_ERC20_BytecodeDrop_FAILED");
    }
}
