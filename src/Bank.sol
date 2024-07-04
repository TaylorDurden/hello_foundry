// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract Bank {
    bool internal locked;
    address public immutable owner;
    mapping(address => uint256) public userBalances;
    address[] public users;
    address[3] public top3Users;
    uint256[3] public top3Amounts;
    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        owner = msg.sender;
    }

    fallback() external payable {}

    receive() external payable {
        userBalances[msg.sender] += msg.value;
        if (!existedUser(msg.sender)) {
            users.push(msg.sender);
        }
        _updateTop3Users(msg.sender, userBalances[msg.sender]);
    }

    function withdraw() external onlyOwner noReentrant {
        require(address(this).balance > 0, "Insufficient balance");
        address[] memory _users = users;
        for (uint256 i = 0; i < _users.length; i++) {
            address user = _users[i];
            uint256 balance = userBalances[user];
            if (balance > 0) {
                console.log(
                    "withdraw: userBalances[user]:",
                    userBalances[user]
                );
                console.log("withdraw: user:", user);
                userBalances[user] = 0;
                (bool s, ) = user.call{value: balance}("");
                require(s);
            }
        }
    }

    function _updateTop3Users(address user, uint256 amount) internal {
        for (uint256 i = 0; i < 3; i++) {
            if (top3Amounts[i] < amount) {
                for (uint256 j = 2; j > i; j--) {
                    top3Amounts[j] = top3Amounts[j - 1];
                    top3Users[j] = top3Users[j - 1];
                }
                top3Amounts[i] = amount;
                top3Users[i] = user;
                console.log("top3Amounts[i]:", top3Amounts[i]);
                console.log("top3Users[i]:", top3Users[i]);
                break;
            }
        }
    }

    function getTop3UserAmount()
        public
        view
        returns (address[3] memory, uint256[3] memory)
    {
        return (top3Users, top3Amounts);
    }

    function existedUser(address user) internal view returns (bool) {
        uint256 length = users.length;
        address[] memory _users = users;
        for (uint256 i = 0; i < length; i++) {
            if (_users[i] == user) {
                return true;
            }
        }
        return false;
    }
}
