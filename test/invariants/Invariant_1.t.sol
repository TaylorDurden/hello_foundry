// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {WETH} from "../../src/WETH.sol";

// Note: open testing - randomly call all public functions
contract WETH_Open_Invariant_Tests is Test {
    WETH public weth;

    function setUp() public {
        weth = new WETH();
    }

    function invariant_totalSupply_is_always_zero() public {
        assertEq(weth.totalSupply(), 0);
    }
}
