// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    function test_incCount() public {
        counter.incCount();
        assertEq(counter.count(), 1);
    }

    function testFail_decCount() public {
        counter.decCount();
    }

    function test_decCount_UnderFlow() public {
        vm.expectRevert(stdError.arithmeticError);
        counter.decCount();
    }

    function test_dec() public {
        counter.incCount();
        counter.incCount();
        counter.decCount();
        assertEq(counter.count(), 1);
    }
}
