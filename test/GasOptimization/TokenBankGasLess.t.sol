// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/GasOptimization/TokenBankGasLess.sol";

contract TokenBankGasLessTest is Test {
  TokenBankGasLess private tokenBank;

  function setUp() public {
    tokenBank = new TokenBankGasLess();
  }

  function testDeposit() public {
    address user = address(123);
    vm.deal(user, 1 ether);
    vm.prank(user);
    tokenBank.deposit{value: 1 ether}();
    assertEq(tokenBank.balances(user), 1 ether);
  }

  function testWithdraw() public {
    address user = address(123);
    vm.deal(user, 2 ether);
    vm.prank(user);
    tokenBank.deposit{value: 1 ether}();
    vm.prank(user);
    tokenBank.withdraw();
    assertEq(tokenBank.balances(user), 0);
    assertEq(user.balance, 2 ether);
  }

  function testTopUsers() public {
    address[11] memory users;
    for (uint256 i = 0; i < 11; i++) {
      users[i] = address(uint160(i + 2));
      vm.deal(users[i], 2 ether);
      vm.prank(users[i]);
      tokenBank.deposit{value: (i + 1) * 0.1 ether}();
    }

    address[] memory topUsers = tokenBank.getTop10Users();
    assertEq(topUsers.length, 10);

    for (uint256 i = 0; i < 10; i++) {
      assertEq(topUsers[i], users[10 - i]);
      if (i == 9) {
        // Check that the 11th user is not in the top 10
        assertTrue(topUsers[i] != users[0]);
      }
    }
  }
}
