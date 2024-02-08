// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Benchmarks.base.sol";

// See Benchmarks.base.sol for more info and to modify the amount of recipients to test with

// ! These benchmarks are not available due to inconsistencies in Forge's estimations.
// ! See: https://github.com/foundry-rs/foundry/issues/7047

// 4. DISPERSE APP
// 5. WENTOKENS
// 6. GASLITE DROP

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

        // Airdrop
        wentokens_airdrop.airdropETH{value: TOTAL_AMOUNT_ERC20}(RECIPIENTS, AMOUNTS);
    }

    /* -------------------------------------------------------------------------- */
    /*                               3. GASLITE DROP                              */
    /* -------------------------------------------------------------------------- */

    function test_ETH_GasliteDrop(uint256) public {
        setup();

        // Airdrop
        gasliteDrop.airdropETH{value: TOTAL_AMOUNT_ERC20}(RECIPIENTS, AMOUNTS);
    }
}
