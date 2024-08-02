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

  function buyETH(uint256 amountIn, address tokenIn, uint256 amountOutMin) external returns (uint[] memory amounts) {
    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = address(WETH);
    IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
    IERC20(tokenIn).approve(address(uniswapV2Router), amountIn);
    amounts = uniswapV2Router.swapExactTokensForETH(amountIn, amountOutMin, path, msg.sender, block.timestamp);
  }

  function sellETH(address tokenOut) external payable returns (uint[] memory amounts) {
    require(msg.value > 0, "You need to sell some ETH");

    address[] memory path = new address[](2);
    path[0] = address(WETH);
    path[1] = tokenOut;

    // to calucalte the expected token amount by swap with eth amount
    uint amountOut = getAmountOut(msg.value, path);

    amounts = uniswapV2Router.swapETHForExactTokens{value: msg.value}(amountOut, path, msg.sender, block.timestamp);
  }

  // 计算用户想要获得的代币数量
  function getAmountOut(uint amountIn, address[] memory path) internal view returns (uint amountOut) {
    // 使用 Uniswap V2 路由器的 getAmountsOut 函数来计算代币数量
    uint[] memory amounts = uniswapV2Router.getAmountsOut(amountIn, path);
    amountOut = amounts[amounts.length - 1];
  }

  // to receive ETH
  receive() external payable {}
}
