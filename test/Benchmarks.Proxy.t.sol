// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SoladyTest} from "solady/test/utils/SoladyTest.sol";
import {LibClone} from "@solady/utils/LibClone.sol";

// Calculate the cost of deploying a proxy for Thirdweb contracts

contract ProxyDeployer {
    function deployProxy(address _implementation) public {
        LibClone.deployERC1967(_implementation);
    }
}

contract BenchmarksProxy is SoladyTest {
    ProxyDeployer deployer;

    function setUp() public {
        deployer = new ProxyDeployer();
    }

    function test_deployProxy_Thirdweb(uint256) public {
        deployer.deployProxy(_randomNonZeroAddress());
    }
}
