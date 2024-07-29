// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

import {InscriptionTokenV1, InscriptionTokenV2} from "../../src/Upgradable/InscriptionToken.sol";
import {InscriptionFactoryV1} from "../../src/Upgradable/UUPSTokenFactoryV1.sol";
import {InscriptionFactoryV2} from "../../src/Upgradable/UUPSTokenFactoryV2.sol";

contract UUPSTokenFactoryTest is Test {
    InscriptionFactoryV1 factoryV1;
    InscriptionFactoryV2 factoryV2;
    InscriptionTokenV1 tokenERC20V1;
    InscriptionTokenV2 tokenERC20V2;
    ERC1967Proxy proxy;

    address owner;
    string constant Symbol = "TT";
    uint256 constant PermitMint = 10 ether;
    uint256 constant TotalSupply = 1000 ether;

    function setUp() public {
        owner = makeAddr("owner");
        vm.deal(owner, 10 ether);

        // vm.startPrank(owner);
        // // deploy proxy

        // vm.stopPrank();
    }

    function testDeployInscriptionV1() public {
        vm.startPrank(owner);
        factoryV1 = new InscriptionFactoryV1();
        proxy = new ERC1967Proxy(
            address(factoryV1),
            abi.encodeWithSelector(InscriptionFactoryV1.initialize.selector)
        );
        (bool s, bytes memory data) = address(proxy).call(
            abi.encodeWithSelector(
                factoryV1.deployInscription.selector,
                Symbol,
                TotalSupply,
                PermitMint
            )
        );
        require(s);
        tokenERC20V1 = InscriptionTokenV1(abi.decode(data, (address)));
        InscriptionTokenV1 token = InscriptionTokenV1(tokenERC20V1);
        assertEq(token.symbol(), Symbol);
        assertEq(token.totalSupply(), TotalSupply);

        (bool s1, ) = address(proxy).call(
            abi.encodeWithSelector(
                factoryV1.mintInscription.selector,
                tokenERC20V1
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
        tokenERC20V2 = new InscriptionTokenV2();
        Upgrades.upgradeProxy(
            address(proxy),
            "UUPSTokenFactoryV2.sol:InscriptionFactoryV2",
            abi.encodeWithSelector(
                InscriptionFactoryV2.setProxyToken.selector,
                address(tokenERC20V2)
            ),
            owner
        );

        // proxy
        // (bool s0, ) = address(proxy).call(
        //     abi.encodeWithSelector(
        //         InscriptionFactoryV2.setERC20TokenAddr.selector,
        //         address(tokenERC20V2)
        //     )
        // );
        // require(s0);
        (, bytes memory data) = address(proxy).call(
            abi.encodeWithSelector(
                InscriptionFactoryV2.deployInscription.selector,
                Symbol,
                TotalSupply,
                PermitMint,
                100
            )
        );
        address token = abi.decode(data, (address));
        (bool s1, ) = address(proxy).call{value: 100}(
            abi.encodeWithSelector(
                InscriptionFactoryV2.mintInscription.selector,
                token
            )
        );
        require(s1);
        assertEq(InscriptionTokenV2(token).perMint(), PermitMint);
        assertEq(InscriptionTokenV2(token).balanceOf(owner), PermitMint);
        assertEq(
            InscriptionTokenV2(token).totalSupply(),
            TotalSupply + PermitMint
        );
        vm.stopPrank();
    }
}
