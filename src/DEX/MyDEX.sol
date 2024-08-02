// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../UniswapV2/interfaces/IUniswapV2Router02.sol";
import "../UniswapV2/interfaces/IERC20.sol";
import "./IWETH.sol";

contract MyDex {
    IUniswapV2Router02 public uniswapV2Router;
    IWETH public WETH;

    constructor(address _uniswapV2Router) {
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        WETH = IWETH(uniswapV2Router.WETH());
    }

    function buyETH(
        uint256 amountIn,
        address tokenIn,
        uint256 amountOut
    ) external {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = address(WETH);
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(uniswapV2Router), amountIn);
        uniswapV2Router.swapExactTokensForETH(
            amountIn,
            (amountIn * 90) / 100,
            path,
            msg.sender,
            block.timestamp
        );
    }

    function sellETH(address tokenOut) external payable {
        require(msg.value > 0, "You need to sell some ETH");

        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = tokenOut;

        uniswapV2Router.swapETHForExactTokens{value: msg.value}(
            msg.value,
            path,
            msg.sender,
            block.timestamp
        );
    }

    // to receive ETH
    receive() external payable {}
}
