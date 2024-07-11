// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract Bank {
    mapping(address => uint) public balanceOf;

    error MyError(uint256 a);

    event Deposit(address indexed user, uint amount);

    function depositETH() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}

contract BankTest is Test {
    Bank bank;
    address user;
    event Deposit(address indexed user, uint amount);

    function setUp() public {
        bank = new Bank();
        user = address(this);
    }

    function testDepositETHOk() public {
        uint amount = 10 ether;

        uint balance = bank.balanceOf(user);

        // Send ether to the user address
        vm.deal(user, amount);

        // Expect the Deposit event
        vm.expectEmit(true, false, false, true);

        emit Deposit(address(user), amount);
        bank.depositETH{value: amount}();

        // Verify the balance
        assertEq(bank.balanceOf(user), balance + amount);
    }

    function testNoAmountDepositETH() public {
        vm.expectRevert("Deposit amount must be greater than 0");
        bank.depositETH{value: 0}();
    }

    function testFuzz_DepositETH(uint96 amount) public {
        vm.assume(amount > 0 ether);
        bank.depositETH{value: amount}();
        assertEq(amount, bank.balanceOf(user));
    }
}
