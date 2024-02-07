// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Benchmarks.base.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAirdropERC20} from "src/thirdweb/deps/IAirdropERC20.sol";

// See Benchmarks.base.sol for more info and to modify the amount of recipients to test with

// 1. MAPPING APPROACH (claim)
// 2. MERKLE TREE APPROACH (claim)
// 3. SIGNATURE APPROACH (claim)
// 4. DISPERSE APP (airdrop)
// 5. WENTOKENS (airdrop)
// 6. GASLITE DROP (airdrop)
// 7. BYTECODE DROP (airdrop)
// 8. THIRDWEB AIRDROP (airdrop)
// 9. THIRDWEB AIRDROP (claim)

contract BenchmarksERC20 is Benchmarks_Base {
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
        erc20.approve((address(airdropClaimMapping_erc20)), TOTAL_AMOUNT_ERC20);
        airdropClaimMapping_erc20.airdropERC20(RECIPIENTS, AMOUNTS);

        // Claim
        for (uint256 i = 0; i < RECIPIENTS.length; i++) {
            vm.prank(RECIPIENTS[i]);
            airdropClaimMapping_erc20.claimERC20();
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                           2. MERKLE TREE APPROACH                          */
    /* -------------------------------------------------------------------------- */

    function test_ERC20_AirdropClaimMerkle(uint256) public {
        setup();

        // Deposit
        erc20.transfer(address(airdropClaimMerkle_erc20), TOTAL_AMOUNT_ERC20);

        // Claim
        for (uint256 i = 0; i < RECIPIENTS.length; i++) {
            bytes32[] memory proof = m.getProof(DATA_ERC20, i);
            // prank doesn't really matter as anyone can claim with a valid proof, since tokens are sent to the recipient
            vm.prank(RECIPIENTS[i]);
            airdropClaimMerkle_erc20.claimERC20(RECIPIENTS[i], AMOUNTS[i], proof);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                            3. SIGNATURE APPROACH                           */
    /* -------------------------------------------------------------------------- */

    function test_ERC20_AirdropClaimSignature(uint256) public {
        setup();

        // Deposit
        erc20.transfer(address(airdropClaimSignature_erc20), TOTAL_AMOUNT_ERC20);

        // Claim
        for (uint256 i = 0; i < RECIPIENTS.length; i++) {
            bytes memory signature = _sign(keccak256(abi.encodePacked(RECIPIENTS[i], AMOUNTS[i])));
            // Same here with prank, some can claim on behalf of the recipient (but tokens are sent to the recipient)
            vm.prank(RECIPIENTS[i]);
            airdropClaimSignature_erc20.claimERC20(RECIPIENTS[i], AMOUNTS[i], signature);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                               4. DISPERSE APP                              */
    /* -------------------------------------------------------------------------- */

    function test_ERC20_Disperse_disperseToken(uint256) public {
        setup();
        // Deploy Disperse with cheatcode because of the pragma solidity ^0.4.25
        address deployed = deployCode("Disperse.sol");
        erc20.approve(deployed, TOTAL_AMOUNT_ERC20);

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
        erc20.approve(deployed, TOTAL_AMOUNT_ERC20);

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

    function test_ERC20_wentokens_airdrop(uint256) public {
        setup();

        // Airdrop
        erc20.approve(address(wentokens_airdrop), TOTAL_AMOUNT_ERC20);
        wentokens_airdrop.airdropERC20(IERC20(address(erc20)), RECIPIENTS, AMOUNTS, TOTAL_AMOUNT_ERC20);
    }

    /* -------------------------------------------------------------------------- */
    /*                               6. GASLITE DROP                              */
    /* -------------------------------------------------------------------------- */

    function test_ERC20_GasliteDrop(uint256) public {
        setup();

        // Airdrop
        erc20.approve(address(gasliteDrop), TOTAL_AMOUNT_ERC20);
        gasliteDrop.airdropERC20(address(erc20), RECIPIENTS, AMOUNTS, TOTAL_AMOUNT_ERC20);
    }

    /* -------------------------------------------------------------------------- */
    /*                              7. BYTECODE DROP                              */
    /* -------------------------------------------------------------------------- */

    /// Note: Forge won't report gas usage for a bytecode contract, so we'll just use
    /// console and `gasleft` to get an idea.
    /// This is not consistent with the other benchmarks, but it's good enough.
    function test_ERC20_BytecodeDrop(uint256) public {
        setup();
        // (address deployed, uint256 gasUsed) = _deployAndReturnGas("BytecodeDrop.sol");
        // console.log("Deployment: %s gas", gasUsed);

        // Airdrop
        erc20.approve(address(bytecodeDrop), TOTAL_AMOUNT_ERC20);
        // console.log(
        //     "Approval: %s gas",
        //     _callAndReturnGas(
        //         address(erc20),
        //         abi.encodeWithSignature("approve(address,uint256)", deployed, TOTAL_AMOUNT_ERC20),
        //         "test_ERC20_BytecodeDrop_FAILED"
        //     )
        // );
        bytecodeDrop.airdropERC20(address(erc20), RECIPIENTS, AMOUNTS, TOTAL_AMOUNT_ERC20);
        // console.log(
        //     "Airdrop: %s gas",
        //     _callAndReturnGas(
        //         deployed,
        //         abi.encodeWithSignature(
        //             "airdropERC20(address,address[],uint256[],uint256)",
        //             address(erc20),
        //             RECIPIENTS,
        //             AMOUNTS,
        //             TOTAL_AMOUNT_ERC20
        //         ),
        //         "test_ERC20_BytecodeDrop_FAILED"
        //     )
        // );
    }

    /* -------------------------------------------------------------------------- */
    /*                             8. THIRDWEB AIRDROP                            */
    /* -------------------------------------------------------------------------- */

    function test_ERC20_AirdropERC20Thirdweb(uint256) public {
        setup();

        // Airdrop
        erc20.approve(address(thirdweb_airdropERC20), TOTAL_AMOUNT_ERC20);
        thirdweb_airdropERC20.airdropERC20(address(erc20), address(this), _toAirdropContent(RECIPIENTS, AMOUNTS));
    }

    function _toAirdropContent(address[] memory _recipients, uint256[] memory _amounts)
        internal
        pure
        returns (IAirdropERC20.AirdropContent[] memory contents)
    {
        contents = new IAirdropERC20.AirdropContent[](_recipients.length);
        for (uint256 i = 0; i < _recipients.length; i++) {
            contents[i] = IAirdropERC20.AirdropContent({recipient: _recipients[i], amount: _amounts[i]});
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                             9. THIRDWEB CLAIM                             */
    /* -------------------------------------------------------------------------- */

    function test_ERC20_AirdropERC20ClaimableThirdweb(uint256) public {
        setup();

        // Approve
        erc20.approve(address(thirdweb_airdropERC20Claimable), TOTAL_AMOUNT_ERC20);

        // Claim
        for (uint256 i = 0; i < RECIPIENTS.length; i++) {
            bytes32[] memory proof = m.getProof(DATA_ERC20, i);
            vm.prank(RECIPIENTS[i]);
            thirdweb_airdropERC20Claimable.claim(RECIPIENTS[i], AMOUNTS[i], proof, AMOUNTS[i]);
        }
    }
}
