// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/DEX/WETH9.sol";
import "../src/UniswapV2/UniswapV2Factory.sol";
import "../src/UniswapV2/UniswapV2Router02.sol";

contract DeployUniswapV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy WETH
        WETH9 weth = new WETH9();
        console.log("WETH deployed at:", address(weth));

        // Deploy UniswapV2Factory
        UniswapV2Factory factory = new UniswapV2Factory(address(this));
        console.log("UniswapV2Factory deployed at:", address(factory));

        // Deploy UniswapV2Router02
        UniswapV2Router02 router = new UniswapV2Router02(
            address(factory),
            address(weth)
        );
        console.log("UniswapV2Router02 deployed at:", address(router));

        vm.stopBroadcast();
    }
}
