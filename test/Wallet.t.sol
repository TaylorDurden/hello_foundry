// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Wallet} from "../src/Wallet.sol";

// Examples of deal and hoax
// deal(address, uint) - Set balance of address
// hoax(address, uint) - deal + prank, Sets up a prank and set balance

contract WalletTest is Test {
    Wallet public wallet;

    // Receive ETH from wallet
    receive() external payable {}

    function setUp() public {
        wallet = new Wallet{value: 1e18}();
    }

    function _sendEth(uint256 amount) private {
        (bool ok, ) = address(wallet).call{value: amount}("");
        require(ok, "send eth failed...");
    }

    function testSendETH() public {
        uint256 initBalance = address(wallet).balance;

        address address1 = address(1);
        deal(address(1), 123);
        vm.prank(address1);
        _sendEth(123);
        assertEq(address1.balance, 0);
        assertEq(address(wallet).balance, initBalance + 123);

        hoax(address1, 456);
        _sendEth(455);
        assertEq(address1.balance, 1);
        assertEq(address(wallet).balance, initBalance + 123 + 455);
    }

    function testFailWithdrawNotOwner() public {
        vm.prank(address(1));
        wallet.withdraw(1);
    }

    // Test fail and check error message
    function testWithdrawRevertNotOwner() public {
        vm.prank(address(1));
        vm.expectRevert(bytes("caller is not owner"));
        wallet.withdraw(1);
    }

    function testWithdraw() public {
        uint256 walletBalanceBefore = address(wallet).balance;
        uint256 ownerBalanceBefore = address(this).balance;

        wallet.withdraw(1);

        uint256 walletBalanceAfter = address(wallet).balance;
        uint256 ownerBalanceAfter = address(this).balance;

        assertEq(walletBalanceAfter, walletBalanceBefore - 1);
        assertEq(ownerBalanceAfter, ownerBalanceBefore + 1);
    }
}
