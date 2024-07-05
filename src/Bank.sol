// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

interface IBank {
    function withdraw() external;

    function withdraw(address, uint256) external;
}

contract Ownable {
    address public owner;
    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner");
        _;
    }
}

error InsufficientDeposit();
error InsufficientBalance();

contract Bank is IBank, Ownable {
    mapping(address => uint256) public userBalances;
    address[] public users;
    address[3] public top3Users;

    modifier sufficientDeposit() {
        if (msg.value <= 0.001 ether) {
            revert InsufficientDeposit();
        }
        _;
    }

    modifier sufficientBalance(address user, uint256 amount) {
        if (userBalances[user] < amount) {
            revert InsufficientBalance();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    fallback() external payable {}

    receive() external payable sufficientDeposit {
        _deposit();
    }

    function _deposit() internal {
        userBalances[msg.sender] += msg.value;
        if (!existedUser(msg.sender)) {
            users.push(msg.sender);
        }
        _updateTop3Users(msg.sender, userBalances[msg.sender]);
    }

    function withdraw(
        address user,
        uint256 amount
    ) external onlyOwner sufficientBalance(user, amount) {
        uint256 balance = userBalances[user];
        if (balance > amount) {
            userBalances[user] -= amount;
            (bool s, ) = user.call{value: amount}("");
            require(s);
        } else {
            revert InsufficientBalance();
        }
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0);
        address[] memory _users = users;
        for (uint256 i = 0; i < _users.length; i++) {
            address user = _users[i];
            uint256 balance = userBalances[user];
            if (balance > 0) {
                userBalances[user] = 0;
                (bool s, ) = user.call{value: balance}("");
                require(s);
            }
        }
    }

    function _updateTop3Users(address user, uint256 amount) internal {
        address[3] memory _topUsers = top3Users;
        for (uint256 i = 0; i < 3; i++) {
            if (userBalances[_topUsers[i]] < amount) {
                for (uint256 j = 2; j > i; j--) {
                    top3Users[j] = top3Users[j - 1];
                }
                top3Users[i] = user;
                break;
            }
        }
    }

    function getTop3UserAmount()
        public
        view
        returns (address[3] memory, uint256[3] memory top3Amounts)
    {
        for (uint256 i = 0; i < 3; i++) {
            top3Amounts[i] = userBalances[top3Users[i]];
        }
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

contract BigBank is Bank {
    event OwnerTransfered(address indexed oldOwner, address indexed newOwner);

    function transferOwner(address newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnerTransfered(oldOwner, newOwner);
    }
}

contract BigBankProxy is Ownable {
    constructor() {
        owner = msg.sender;
    }

    function transferBigBankOwner(BigBank bigBank, address user) public {
        bigBank.transferOwner(user);
    }

    function withdraw(
        IBank bigBank,
        address user,
        uint256 amount
    ) public onlyOwner {
        bigBank.withdraw(user, amount);
    }
}
