// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Auction} from "../src/Auction.sol";

contract TimeTest is Test {
    Auction public auction;
    uint256 private startAt;
    // vm.warp - set block.timestamp to future timestamp
    // vm.roll - set block.number
    // skip - increment current timestamp
    // rewind - decrement current timestamp

    function setUp() public {
        auction = new Auction();
        startAt = block.timestamp;
    }

    function testBidFailsBeforeStartTime() public {
        vm.expectRevert(bytes("cannot bid"));
        auction.bid();
    }

    function testBid() public {
        vm.warp(startAt + 1.5 days);
        auction.bid();
    }

    function testBidFailsAfterEndTime() public {
        vm.expectRevert(bytes("cannot bid"));
        vm.warp(startAt + 2.5 days);
        auction.bid();
    }

    function testEndFails() public {
        vm.expectRevert(bytes("cannot end"));
        auction.end();
    }

    function testEndFailsWhenBidding() public {
        vm.warp(startAt + 1.5 days);
        auction.bid();
        vm.expectRevert(bytes("cannot end"));
        auction.end();
    }

    function testEndSuccess() public {
        vm.warp(startAt + 2 days);
        auction.end();
    }

    function testTimestamp() public {
        uint256 t = block.timestamp;
        // set block.timestamp to t + 100
        skip(100);
        assertEq(t + 100, block.timestamp);

        // set block.timestamp to t + 100 - 100;
        rewind(100);
        assertEq(t, block.timestamp);
    }

    function testBlockNumber() public {
        // set block number to 11
        vm.roll(11);
        assertEq(11, block.number);
    }
}
