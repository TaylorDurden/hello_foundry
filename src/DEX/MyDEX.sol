// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;
// import "../UniswapV2/interfaces/IUniswapV2Router02.sol";
// import "../UniswapV2/interfaces/IERC20.sol";
// import "../UniswapV2/interfaces/IWETH.sol";

// contract MyDex {
//     IUniswapV2Router02 public uniswapV2Router;
//     IWETH public WETH;

//     constructor(address _uniswapV2Router, address _WETH) {
//         uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
//         WETH = IWETH(_WETH);
//     }

//     function buyETH() external payable {
//         require(msg.value > 0, "You need to send some ETH");

//         WETH.deposit{value: msg.value}();
//         WETH.approve(address(uniswapV2Router), msg.value);

//         path[0] = address(WETH);
//         path[1] = uniswapV2Router.WETH();

//         uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
//             msg.value,
//             0, // accept any amount of ETH
//             path,
//             msg.sender,
//             block.timestamp
//         );
//     }

//     function sellETH(uint256 amount) external {
//         require(amount > 0, "You need to sell some ETH");

//         WETH.deposit{value: amount}();
//         WETH.approve(address(uniswapV2Router), amount);

//         path[0] = uniswapV2Router.WETH();
//         path[1] = address(WETH);

//         uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
//             value: amount
//         }(
//             0, // accept any amount of WETH
//             path,
//             msg.sender,
//             block.timestamp
//         );
//     }

//     // to receive ETH
//     receive() external payable {}
// }
