// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

import {InscriptionToken} from "../../src/Upgradable/InscriptionToken.sol";
import {InscriptionFactoryV1} from "../../src/Upgradable/UUPSTokenFactoryV1.sol";
import {InscriptionFactoryV2} from "../../src/Upgradable/UUPSTokenFactoryV2.sol";

contract UUPSTokenFactoryTest is Test {
    InscriptionFactoryV1 factoryV1;
    InscriptionFactoryV2 factoryV2;
    address tokenERC20;
    ERC1967Proxy proxy;

    address owner;
    string constant Symbol = "TT";
    uint256 constant PermitMint = 10 ether;
    uint256 constant TotalSupply = 1000 ether;

    function setUp() public {
        owner = makeAddr("owner");

        // vm.startPrank(owner);
        // // deploy proxy

        // vm.stopPrank();
    }

    function testDeployInscriptionV1() public {
        vm.startPrank(owner);
        factoryV1 = new InscriptionFactoryV1();
        proxy = new ERC1967Proxy(address(factoryV1), "");
        (bool s, bytes memory data) = address(proxy).call(
            abi.encodeWithSelector(
                factoryV1.deployInscription.selector,
                Symbol,
                TotalSupply,
                PermitMint
            )
        );
        require(s);
        tokenERC20 = abi.decode(data, (address));
        InscriptionToken token = InscriptionToken(tokenERC20);
        assertEq(token.symbol(), Symbol);
        assertEq(token.totalSupply(), TotalSupply);

        (bool s1, ) = address(proxy).call(
            abi.encodeWithSelector(
                factoryV1.mintInscription.selector,
                tokenERC20
            )
        );
        require(s1);
        assertEq(token.totalSupply(), TotalSupply + PermitMint);
        assertEq(token.balanceOf(owner), PermitMint);
        vm.stopPrank();
    }

    function testDeployInscriptionV2() public {
        testDeployInscriptionV1();
        vm.startPrank(owner);
        factoryV2 = new InscriptionFactoryV2();
        Upgrades.upgradeProxy(
            address(proxy),
            "UUPSTokenFactoryV2.sol:InscriptionFactoryV2",
            "",
            owner
        );
        // factoryV2.setERC20TokenAddr(tokenERC20);
        // proxy
        (bool s0, ) = address(proxy).call(
            abi.encodeWithSelector(
                factoryV2.setERC20TokenAddr.selector,
                tokenERC20
            )
        );
        require(s0);
        (, bytes memory data) = address(proxy).call(
            abi.encodeWithSelector(
                factoryV2.deployInscription.selector,
                Symbol,
                TotalSupply,
                PermitMint,
                100
            )
        );
        address token = abi.decode(data, (address));
        // assertEq(InscriptionToken(token).symbol(), Symbol);
        // assertEq(InscriptionToken(token).totalSupply(), TotalSupply);

        (bool s1, ) = address(proxy).call(
            abi.encodeWithSelector(factoryV2.mintInscription.selector, token)
        );
        require(s1);
        // assertEq(
        //     InscriptionToken(token).totalSupply(),
        //     TotalSupply + PermitMint
        // );
        assertEq(InscriptionToken(token).perMint(), PermitMint);
        assertEq(InscriptionToken(token).balanceOf(owner), PermitMint);
        assertEq(
            InscriptionToken(token).totalSupply(),
            TotalSupply + PermitMint
        );
        vm.stopPrank();
    }
}
