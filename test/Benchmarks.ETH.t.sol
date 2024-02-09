// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Benchmarks.base.sol";

// See Benchmarks.base.sol for more info and to modify the amount of recipients to test with

// 1. DISPERSE APP
// 2. WENTOKENS
// 3. GASLITE DROP
// 4. GASLITE MERKLE DN

contract BenchmarksETH is Benchmarks_Base {
    /* -------------------------------------------------------------------------- */
    /*                                    SETUP                                   */
    /* -------------------------------------------------------------------------- */

    function _setType() internal override {
        testType = TEST_TYPE.ETH;
    }

    /* -------------------------------------------------------------------------- */
    /*                               1. DISPERSE APP                              */
    /* -------------------------------------------------------------------------- */

    function test_ETH_Disperse(uint256) public {
        setup();
        _initializeAccounts();

        // Deploy Disperse with cheatcode because of the pragma solidity ^0.4.25
        address deployed = deployCode("Disperse.sol");

        // Airdrop ("disperse")
        (bool success,) = deployed.call{value: TOTAL_AMOUNT_ERC20}(
            abi.encodeWithSignature("disperseEther(address[],uint256[])", RECIPIENTS, AMOUNTS)
        );
        if (!success) revert("test_ETH_Disperse_FAILED");
    }

    /* -------------------------------------------------------------------------- */
    /*                                2. WENTOKENS                                */
    /* -------------------------------------------------------------------------- */

    function test_ETH_AirdropWentokens(uint256) public {
        setup();
        _initializeAccounts();

        // Airdrop
        wentokens_airdrop.airdropETH{value: TOTAL_AMOUNT_ERC20}(RECIPIENTS, AMOUNTS);
    }

    /* -------------------------------------------------------------------------- */
    /*                               3. GASLITE DROP                              */
    /* -------------------------------------------------------------------------- */

    function test_ETH_GasliteDrop(uint256) public {
        setup();
        _initializeAccounts();

        // Airdrop
        gasliteDrop.airdropETH{value: TOTAL_AMOUNT_ERC20}(RECIPIENTS, AMOUNTS);
    }

    /* -------------------------------------------------------------------------- */
    /*                            4. GASLITE MERKLE DN                            */
    /* -------------------------------------------------------------------------- */

    function test_ETH_GasliteMerkleDN(uint256) public {
        setup();

        // Deposit
        (bool success,) = address(gasliteMerkleDN).call{value: TOTAL_AMOUNT_ERC20}("");
        if (!success) revert("test_ETH_GasliteMerkle_FAILED");
        // Set active
        gasliteMerkleDN.toggleActive();

        // Claim
        for (uint256 i = 0; i < RECIPIENTS.length; i++) {
            bytes32[] memory proof = m.getProof(DATA_ERC20, i);
            vm.prank(RECIPIENTS[i]);
            gasliteMerkleDN.claim(proof, AMOUNTS[i]);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                    UTILS                                   */
    /* -------------------------------------------------------------------------- */

    // Initialize accounts; that is, send some native tokens so the measurement won't account
    // for both the cold account access (2,500 gas) and the initialization surcharges (25,000 gas).
    // It would not really make sense to airdrop only a bunch of uninitialized accounts.
    //  See: https://github.com/foundry-rs/foundry/issues/7047
    function _initializeAccounts() internal {
        for (uint256 i = 0; i < RECIPIENTS.length; i++) {
            (bool success,) = RECIPIENTS[i].call{value: 1 wei}("");
            if (!success) revert("initializeAccounts_FAILED");
        }
    }
}
