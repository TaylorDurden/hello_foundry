// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Test.sol";

contract Wallet {
    address payable public walletOwner;

    event Deposit(address account, uint256 amount);

    constructor() payable {
        walletOwner = payable(msg.sender);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == walletOwner, "caller is not owner");
        payable(msg.sender).transfer(_amount);
    }

    function setOwner(address _newOwner) external {
        console.log("msg.sender:", msg.sender);
        console.log("walletOwner:", walletOwner);
        require(msg.sender == walletOwner, "caller is not owner");
        walletOwner = payable(_newOwner);
    }
}
