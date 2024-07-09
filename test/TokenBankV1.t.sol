// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/TokenBankV1.sol";
import "../src/ERC1363/ERC1363.sol";
import "../src/interfaces/IERC1363.sol";

contract MockERC1363 is ERC1363 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000 * 10 ** 18);
    }
}

contract TokenBankV1Test is Test {
    TokenBankV1 public bank;
    MockERC1363 public tokenA;
    MockERC1363 public tokenB;
    address public user;

    function setUp() public {
        bank = new TokenBankV1();
        tokenA = new MockERC1363("TokenA", "TKA");
        tokenB = new MockERC1363("TokenB", "TKB");
        user = address(1);

        tokenA.transfer(user, 1000 * 10 ** 18);
        tokenB.transfer(user, 1000 * 10 ** 18);
    }

    function testDeposit() public {
        vm.startPrank(user);
        tokenA.transferAndCall(address(bank), 100 * 10 ** 18);
        tokenB.transferAndCall(address(bank), 200 * 10 ** 18);
        vm.stopPrank();

        assertEq(bank.userTokenBalance(user, address(tokenA)), 100 * 10 ** 18);
        assertEq(bank.userTokenBalance(user, address(tokenB)), 200 * 10 ** 18);
    }

    function testWithdraw() public {
        vm.startPrank(user);
        tokenA.transferAndCall(address(bank), 100 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(user);
        bank.withdraw(address(tokenA), 50 * 10 ** 18);
        vm.stopPrank();

        assertEq(bank.userTokenBalance(user, address(tokenA)), 50 * 10 ** 18);
        assertEq(tokenA.balanceOf(user), 950 * 10 ** 18);
    }

    function testWithdrawInsufficientBalance() public {
        vm.startPrank(user);
        tokenA.transferAndCall(address(bank), 50 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert("Insufficient balance");
        bank.withdraw(address(tokenA), 100 * 10 ** 18);
        vm.stopPrank();
    }

    function testDepositAndApprove() public {
        vm.startPrank(user);
        tokenA.approveAndCall(address(bank), 100 * 10 ** 18);
        vm.stopPrank();

        assertEq(bank.userTokenBalance(user, address(tokenA)), 100 * 10 ** 18);
    }
}
