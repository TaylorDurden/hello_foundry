// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {InscriptionTokenV2} from "../src/Upgradable/InscriptionToken.sol";
import {InscriptionFactoryV2} from "../src/Upgradable/UUPSTokenFactoryV2.sol";

contract UUPSTokenFactoryV2 is Script {
    function setUp() public {}

    function run() public {
        address proxy = 0x578E343abe891A8B4144358a1572a5775aA95116;
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address account = vm.addr(privateKey);

        console.log("Account", account);

        vm.startBroadcast(privateKey);
        InscriptionTokenV2 tokenV2 = new InscriptionTokenV2();
        Upgrades.upgradeProxy(
            proxy,
            "UUPSTokenFactoryV2.sol:InscriptionFactoryV2",
            abi.encodeWithSelector(
                InscriptionFactoryV2.setProxyToken.selector,
                address(tokenV2)
            ),
            account
        );

        vm.stopBroadcast();
    }
}
