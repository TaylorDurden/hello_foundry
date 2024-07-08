// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";

contract TokenBank {
    IERC20 public token;
    mapping(address => uint256) public balanceOf;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
    }

    function deposit(uint256 amount) public {
        require(amount > 0, "Insufficient deposit amount");
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );

        balanceOf[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        require(amount > 0, "Insufficient withdraw amount");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        require(
            token.transfer({recipient: msg.sender, amount: amount}),
            "Token transfer failed"
        );

        emit Withdraw(msg.sender, amount);
    }
}
