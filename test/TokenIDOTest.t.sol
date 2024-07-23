// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TokenIDO, RNTToken} from "../src/IDO/TokenIDO.sol";

contract TokenIDOTest is Test {
    RNTToken token;
    TokenIDO ido;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    address owner = makeAddr("owner");
    error OnlyWhenIDOSucceed();
    error OnlyWhenIDOFailed();
    error OnlyWhenIDOActive();

    function setUp() public {
        token = new RNTToken("RNT Token", "RNT");
        ido = new TokenIDO(token, owner);
        // Transfer 1 million tokens to the IDO contract
        token.makeIDO(1 * 10 ** 6 * 10 ** token.decimals(), address(ido));
    }

    function testPresale() public {
        // Alice participates in the presale
        vm.startPrank(alice);
        vm.deal(alice, 1 ether); // Give Alice some ETH
        ido.presale{value: 0.01 ether}();
        assertEq(ido.balanceOf(alice), 0.01 ether);
        vm.stopPrank();

        // Bob participates in the presale
        vm.startPrank(bob);
        vm.deal(bob, 1 ether); // Give Bob some ETH
        ido.presale{value: 0.05 ether}();
        assertEq(ido.balanceOf(bob), 0.05 ether);
        vm.stopPrank();
    }

    function testPresaleMinMaxValue() public {
        // Testing minimum value
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        vm.expectRevert();
        ido.presale{value: 0.009 ether}(); // Below minimum value
        vm.stopPrank();

        // Testing maximum value
        vm.startPrank(bob);
        vm.deal(bob, 1 ether);
        vm.expectRevert();
        ido.presale{value: 0.11 ether}(); // Above maximum value
        vm.stopPrank();
    }

    function testMultiplePresale() public {
        // Alice participates multiple times in the presale
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        ido.presale{value: 0.01 ether}();
        assertEq(ido.balanceOf(alice), 0.01 ether);
        ido.presale{value: 0.02 ether}();
        assertEq(ido.balanceOf(alice), 0.03 ether);
        vm.stopPrank();
    }

    function testPresaleWhenEnd() public {
        // Alice participates multiple times in the presale
        vm.warp(block.timestamp + 31 days);
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        vm.expectRevert(OnlyWhenIDOActive.selector);
        ido.presale{value: 0.01 ether}();
        assertEq(ido.balanceOf(alice), 0);
        vm.stopPrank();
    }

    function testClaim() public {
        // Alice participates in the presale
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        ido.presale{value: 0.01 ether}();
        vm.stopPrank();

        // Move forward in time to end the presale
        vm.warp(block.timestamp + 31 days);

        // Assuming presale succeeded
        vm.deal(address(ido), 100 ether);

        // Claim tokens
        vm.prank(alice);
        ido.claim();
        uint256 expectedTokenBalance = ((1 * 10 ** 6 * 0.01 ether) /
            (address(ido).balance)) * 10 ** token.decimals();
        assertEq(token.balanceOf(alice), expectedTokenBalance);
    }

    function testRefund() public {
        // Alice participates in the presale
        vm.startPrank(alice);
        vm.deal(alice, 1 ether); // Give Alice some ETH
        ido.presale{value: 0.01 ether}();
        assertEq(ido.balanceOf(alice), 0.01 ether);
        vm.stopPrank();

        // Move forward in time to end the presale
        vm.warp(block.timestamp + 30 days);
        // Assuming presale failed
        vm.prank(alice);
        ido.refund();
        // Check balance
        assertEq(alice.balance, 1 ether);
        assertEq(ido.balanceOf(alice), 0);
        assertEq(address(ido).balance, 0);
    }

    function testPresaleFailureAfterEndTime() public {
        // Move forward in time to end the presale
        vm.warp(block.timestamp + 31 days);
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        vm.expectRevert(OnlyWhenIDOActive.selector);
        ido.presale{value: 0.01 ether}();
        vm.stopPrank();
    }

    function testWithdrawAfterSuccess() public {
        // Assuming presale succeeded
        vm.deal(address(ido), 100 ether);
        // Alice participates in the presale
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        ido.presale{value: 0.01 ether}();
        vm.stopPrank();
        assertEq(address(ido).balance, 100 ether + 0.01 ether);

        // Move forward in time to end the presale
        vm.warp(block.timestamp + 31 days);

        vm.prank(owner);
        ido.withdraw();
        // Check balance
        assertEq(address(ido).balance, 0);
        assertEq(owner.balance, 100 ether + 0.01 ether);
    }

    function testWithdrawAfterFailure() public {
        // Alice participates in the presale
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        ido.presale{value: 0.01 ether}();
        vm.stopPrank();

        // Move forward in time to end the presale
        vm.warp(block.timestamp + 31 days);

        // Assuming presale failed
        vm.expectRevert(OnlyWhenIDOSucceed.selector);
        vm.prank(owner);
        ido.withdraw();
    }
}
