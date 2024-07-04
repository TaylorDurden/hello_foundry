// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {
    Bank bank;
    address owner;
    address user1;
    address user2;
    address user3;
    address user4;
    uint256 initEther = 10 ether;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x3);
        user4 = address(0x4);

        bank = new Bank();
    }

    function testDeposit() public {
        vm.deal(user1, 10 ether);
        vm.startPrank(user1);
        (bool success, ) = address(bank).call{value: 5 ether}("");
        assert(success);
        (bool success1, ) = address(bank).call{value: 3 ether}("");
        assert(success1);
        assertEq(bank.userBalances(user1), 8 ether);
        assertEq(user1.balance, 2 ether);
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.deal(user1, initEther);
        vm.deal(user2, initEther);
        vm.deal(user3, initEther);

        uint256 user1TransFee = 5 ether;
        uint256 user2TransFee = 7 ether;
        uint256 user3TransFee = 3 ether;

        uint256 balanceBefore1 = user1.balance;
        uint256 balanceBefore2 = user2.balance;
        uint256 balanceBefore3 = user3.balance;

        vm.prank(user1);
        (bool s1, ) = address(bank).call{value: user1TransFee}("");
        assert(s1);

        vm.prank(user2);
        (bool s2, ) = address(bank).call{value: user2TransFee}("");
        assert(s2);

        vm.prank(user3);
        (bool s3, ) = address(bank).call{value: user3TransFee}("");
        assert(s3);

        uint256 balanceAfter1 = user1.balance;
        uint256 balanceAfter2 = user2.balance;
        uint256 balanceAfter3 = user3.balance;

        // Call the withdraw function
        vm.prank(owner);
        bank.withdraw();

        console.log("user1.balance:", user1.balance);
        console.log("balanceBefore1:", balanceBefore1);
        assertEq(user1.balance, initEther);
        assertEq(user2.balance, initEther);
        assertEq(user3.balance, initEther);

        assertEq(balanceBefore1, balanceAfter1 + user1TransFee);
        assertEq(balanceBefore2, balanceAfter2 + user2TransFee);
        assertEq(balanceBefore3, balanceAfter3 + user3TransFee);

        assertEq(bank.userBalances(user1), 0);
        assertEq(bank.userBalances(user2), 0);
        assertEq(bank.userBalances(user3), 0);
    }

    function testTop3Users() public {
        vm.deal(user1, initEther);
        vm.deal(user2, initEther);
        vm.deal(user3, initEther);
        vm.deal(user4, initEther);

        uint256 user1_5Ether = 5 ether;
        uint256 user2_7Ether = 7 ether;
        uint256 user3_3Ether = 3 ether;
        uint256 user4_4Ether = 4 ether;

        vm.prank(user1);
        (bool s1, ) = address(bank).call{value: user1_5Ether}("");
        require(s1);

        vm.prank(user2);
        (bool s2, ) = address(bank).call{value: user2_7Ether}("");
        require(s2);

        vm.prank(user3);
        (bool s3, ) = address(bank).call{value: user3_3Ether}("");
        require(s3);

        vm.prank(user4);
        (bool s4, ) = address(bank).call{value: user4_4Ether}("");
        require(s4);

        vm.prank(owner);
        (address[3] memory top3Users, uint256[3] memory top3Amounts) = bank
            .getTop3UserAmount();

        assertEq(top3Users[0], user2);
        assertEq(top3Amounts[0], user2_7Ether);

        assertEq(top3Users[1], user1);
        assertEq(top3Amounts[1], user1_5Ether);

        assertEq(top3Users[2], user4);
        assertEq(top3Amounts[2], user4_4Ether);
    }

    function testNoReentrant() public {
        vm.deal(user1, initEther);

        vm.prank(user1);
        (bool s1, ) = address(bank).call{value: 5 ether}("");
        assert(s1);

        // Attempt reentrancy attack by calling withdraw from user1
        vm.startPrank(user1);
        bytes memory payload = abi.encodeWithSignature("withdraw()");
        vm.expectRevert("Only owner");
        (bool revertsAsExpected, ) = address(bank).call(payload);
        assertTrue(revertsAsExpected);
        vm.stopPrank();
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        (bool success1, ) = address(bank).call{value: 5 ether}("");
        assert(success1);

        vm.prank(user2);
        vm.expectRevert("Only owner");
        bytes memory payload = abi.encodeWithSignature("withdraw()");
        (bool revertsAsExpected, ) = address(bank).call(payload);
        assertTrue(revertsAsExpected, "expectRevert: call did not revert");
    }

    function testFallback() public {
        (bool s, ) = address(bank).call(
            abi.encodeWithSignature("nonExistedFunc")
        );
        assert(s);
    }
}
