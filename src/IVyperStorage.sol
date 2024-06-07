// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

interface IVyperStorage {
    function store(uint256 val) external;
    function get() external returns (uint256);
}
