// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ERC20} from "../src/ERC20.sol";
import {TokenBank} from "../src/TokenBank.sol";

contract MyToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract TokenBankTest is Test {
    MyToken token;
    TokenBank tokenBank;
    address deployer;
    address user1;
    address user2;
    uint256 tokenUint = 10 ** 18;
    uint256 mintAmount = 100000 * tokenUint;
    uint256 allowanceAmount = 1000 * tokenUint;
    uint256 oneHundredToken = 100 * tokenUint;
    uint256 twoHundredToken = 200 * tokenUint;
    uint256 userInitTokenAmount = 10000 * 10 ** 18;

    function setUp() public {
        token = new MyToken("MyTestToken", "MTT", 18);
        tokenBank = new TokenBank(token);
        deployer = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        token.mint(deployer, mintAmount);
        token.mint(user1, userInitTokenAmount);
        token.mint(user2, userInitTokenAmount);
    }

    function testDepoist() public {
        vm.startPrank(user1);
        token.approve(address(tokenBank), allowanceAmount);
        tokenBank.deposit(oneHundredToken);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(tokenBank), allowanceAmount);
        tokenBank.deposit(twoHundredToken);
        vm.stopPrank();

        console.log("---assert deposit 1---");
        assertEq(
            token.allowance(user1, address(tokenBank)),
            allowanceAmount - oneHundredToken
        );
        assertEq(
            token.allowance(user2, address(tokenBank)),
            (allowanceAmount - twoHundredToken)
        );
        assertEq(tokenBank.balanceOf(user1), oneHundredToken);
        assertEq(tokenBank.balanceOf(user2), twoHundredToken);
        assertEq(token.balanceOf(user1), userInitTokenAmount - oneHundredToken);
        assertEq(token.balanceOf(user2), userInitTokenAmount - twoHundredToken);
    }

    function testWithdraw() public {
        uint256 threeHundredToken = oneHundredToken + twoHundredToken;
        vm.startPrank(user1);
        token.approve(address(tokenBank), allowanceAmount);
        tokenBank.deposit(oneHundredToken);
        tokenBank.deposit(oneHundredToken);
        vm.stopPrank();
        vm.startPrank(user2);
        token.approve(address(tokenBank), allowanceAmount);
        tokenBank.deposit(threeHundredToken);
        vm.stopPrank();
        console.log("---assert deposit---");
        assertEq(tokenBank.balanceOf(user1), twoHundredToken);
        assertEq(tokenBank.balanceOf(user2), threeHundredToken);
        assertEq(token.balanceOf(user1), userInitTokenAmount - twoHundredToken);
        assertEq(
            token.balanceOf(user2),
            userInitTokenAmount - threeHundredToken
        );
        assertEq(
            token.allowance(user1, address(tokenBank)),
            allowanceAmount - twoHundredToken
        );
        assertEq(
            token.allowance(user2, address(tokenBank)),
            allowanceAmount - threeHundredToken
        );

        console.log("---assert withdraw 1---");
        vm.prank(user1);
        tokenBank.withdraw(oneHundredToken);
        assertEq(tokenBank.balanceOf(user1), oneHundredToken);
        assertEq(
            token.balanceOf(user1),
            userInitTokenAmount - tokenBank.balanceOf(user1)
        );

        console.log("---assert withdraw 2---");
        vm.prank(user2);
        tokenBank.withdraw(oneHundredToken);
        assertEq(tokenBank.balanceOf(user2), twoHundredToken);
        assertEq(
            token.balanceOf(user2),
            userInitTokenAmount - tokenBank.balanceOf(user2)
        );
    }

    function testDepositInsufficientAmount() public {
        vm.startPrank(user1);
        token.approve(address(tokenBank), 100 * 10 ** 18);
        vm.expectRevert("Insufficient deposit amount");
        tokenBank.deposit(0);
        vm.stopPrank();
    }

    function testDepositTokenTransferFailed() public {
        vm.startPrank(user1);
        vm.expectRevert("Allowance exceeded");
        tokenBank.deposit(100 * 10 ** 18);
        vm.stopPrank();
    }

    function testWithdrawInsufficientAmount() public {
        vm.startPrank(user1);
        vm.expectRevert("Insufficient withdraw amount");
        tokenBank.withdraw(0);
        vm.stopPrank();
    }

    function testWithdrawInsufficientBalance() public {
        vm.startPrank(user1);
        token.approve(address(tokenBank), 100 * 10 ** 18);
        tokenBank.deposit(100 * 10 ** 18);

        vm.expectRevert("Insufficient balance");
        tokenBank.withdraw(200 * 10 ** 18);
        vm.stopPrank();
    }
}
