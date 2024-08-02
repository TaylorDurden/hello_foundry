// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/UniswapV2/UniswapV2Pair.sol";

contract GetUniswapV2PairHash is Script {
    function run() external {
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 hash = keccak256(abi.encodePacked(bytecode));
        console.logBytes32(hash);
    }
}
