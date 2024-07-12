// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/Script.sol";

contract MyToken is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, 1e10 * 1e18);
    }
}

contract DeployMyToken is Script {
    function run() external {
        // 从环境变量中获取私钥
        // uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // 设置 deployer 地址
        vm.startBroadcast();

        // 部署合约
        MyToken myToken = new MyToken("MyToken", "MTK");

        vm.stopBroadcast();
    }
}
