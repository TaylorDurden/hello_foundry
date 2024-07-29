// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {InscriptionFactoryV1} from "../src/Upgradable/UUPSTokenFactoryV1.sol";

contract UUPSTokenFactoryV1 is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address account = vm.addr(privateKey);

        console.log("Account", account);

        vm.startBroadcast(privateKey);
        InscriptionFactoryV1 factoryV1 = new InscriptionFactoryV1();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(factoryV1),
            abi.encodeWithSelector(InscriptionFactoryV1.initialize.selector)
        );

        string memory content = string(
            abi.encodePacked(
                "InscriptionFactoryV1: ",
                vm.toString(address(factoryV1)),
                "\n",
                "UUPS Proxy: ",
                vm.toString(address(proxy)),
                "\n"
            )
        );

        // write to file
        vm.writeFile("uups_token_factoryV1.txt", content);

        vm.stopBroadcast();
    }
}
