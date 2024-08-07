// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/console.sol";

contract TokenBankGasLess {
  mapping(address => uint256) public balances;

  /**
   * @dev for example: GUARD(0) => alice(45) => bob(40) => Carol(30)
   */
  mapping(address => address) private _nextUsers;
  address private constant GUARD = address(1);
  uint256 public listSize;

  constructor() {
    _nextUsers[GUARD] = GUARD;
  }

  // Function to deposit ETH into the contract
  function deposit() public payable {
    require(msg.value > 0, "Deposit amount must be greater than zero");
    balances[msg.sender] += msg.value;

    // Update the linked list
    address prevUser = _findPrevUser(msg.sender);
    if (prevUser == address(0)) {
      return;
    }

    console.log("prevUser:", prevUser);
    console.log("_nextUsers[msg.sender]:", _nextUsers[msg.sender]);

    // new user
    if (_nextUsers[msg.sender] == address(0)) {
      _nextUsers[msg.sender] = _nextUsers[prevUser];
      _nextUsers[prevUser] = msg.sender;
      listSize++;
      console.log("_nextUsers[msg.sender] == address(0):", _nextUsers[msg.sender] == address(0));
      console.log("deposit{0} listSize{1}:", msg.sender, listSize);

      // Remove the last user if list size exceeds 10
      if (listSize > 10) {
        _removeLastUser();
      }
    } else {
      console.log("666666");
      _updateList(prevUser, msg.sender);
    }
  }

  // Function to withdraw all ETH from the contract
  function withdraw() public {
    uint256 balance = balances[msg.sender];
    require(balance > 0, "Insufficient balance");
    console.log(1);
    balances[msg.sender] = 0;
    address prevUser = _findPrevUser(msg.sender);
    console.log(2);
    _nextUsers[prevUser] = _nextUsers[msg.sender];
    console.log(3);
    _nextUsers[msg.sender] = address(0);
    console.log(4);
    listSize--;
    console.log(5);

    payable(msg.sender).transfer(balance);
    console.log(6);
  }

  // Get the top 10 users
  function getTop10Users() public view returns (address[] memory) {
    address[] memory topUsers = new address[](listSize);
    address currentAddress = _nextUsers[GUARD];
    for (uint256 i = 0; i < listSize; i++) {
      topUsers[i] = currentAddress;
      currentAddress = _nextUsers[currentAddress];
    }
    return topUsers;
  }

  // Find the previous user in the sorted linked list
  function _findPrevUser(address user) internal view returns (address) {
    address currentAddress = GUARD;
    while (_nextUsers[currentAddress] != GUARD && balances[_nextUsers[currentAddress]] > balances[user]) {
      currentAddress = _nextUsers[currentAddress];
    }
    return currentAddress;
  }

  // Update the linked list when a user's balance changes
  function _updateList(address prevUser, address user) internal {
    _nextUsers[prevUser] = _nextUsers[user];
    address newPrevUser = _findPrevUser(user);
    _nextUsers[user] = _nextUsers[newPrevUser];
    _nextUsers[newPrevUser] = user;
  }

  // Remove the last user from the linked list if it exceeds 10 users
  function _removeLastUser() internal {
    address currentAddress = GUARD;
    for (uint256 i = 0; i < 9; i++) {
      currentAddress = _nextUsers[currentAddress];
    }
    _nextUsers[currentAddress] = GUARD;
    listSize--;
  }
}
