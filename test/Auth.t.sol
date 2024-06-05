// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Wallet} from "../src/Wallet.sol";

contract AuthTest is Test {
    Wallet public wallet;

    function setUp() public {
        wallet = new Wallet();
    }

    function testSetOwner() public {
        wallet.setOwner((address(1)));
        assertEq(wallet.walletOwner(), address(1));
    }

    function testFailSetOwner() public {
        // only next call will be called by address(1)
        vm.prank(address(1));
        // msg.sender = address(1)
        wallet.setOwner(address(1));
        // msg.sender will recover to the contract
        // msg.sender = address(this)
        wallet.setOwner(address(1));
    }

    function testFailSetOwnerAgain() public {
        wallet.setOwner(address(1));
        // all next calls will be called by address(1)
        vm.startPrank(address(1));
        // msg.sender = address(1) for below 3 lines
        wallet.setOwner(address(1));
        wallet.setOwner(address(1));
        wallet.setOwner(address(1));

        vm.stopPrank();

        // msg.sender = address(this)
        wallet.setOwner(address(1));
    }
}
