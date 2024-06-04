// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;
    uint256 public count;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function getCount() public view returns (uint256) {
        return count;
    }

    function incCount() public {
        count += 1;
    }

    function decCount() public {
        // This function will fail if count == 0
        count -= 1;
    }
}
