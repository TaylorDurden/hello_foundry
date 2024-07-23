// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RNTToken, esRNTToken, StakingPool} from "../src/Stake/TokenStake.sol";

contract StakingContractTest is Test {
    RNTToken rntToken;
    esRNTToken esRntToken;
    StakingPool stakingContract;
    address public alice;
    uint256 public alicePK;
    address public bob = makeAddr("bob");
    address public owner = makeAddr("owner");
    uint256 public amountPermit100Ether = 100 ether;
    uint256 public nonce;
    uint256 public deadline;

    function setUp() public {
        (alice, alicePK) = makeAddrAndKey("alice");
        rntToken = new RNTToken();
        esRntToken = new esRNTToken();
        stakingContract = new StakingPool(
            IERC20(address(rntToken)),
            esRntToken
        );

        // Mint some tokens for testing
        rntToken.transfer(alice, 1000 ether);
        rntToken.transfer(bob, 1000 ether);
        nonce = rntToken.nonces(alice);
        deadline = block.timestamp + 1 days;

        esRntToken.transfer(address(stakingContract), 10000 ether); // Fund the staking contract with esRNT tokens
    }

    function testStakeWithPermit() public {
        vm.startPrank(alice);

        (uint8 v, bytes32 r, bytes32 s) = _generatePermitSignature(alice);

        stakingContract.stakePermit(amountPermit100Ether, deadline, v, r, s);
        vm.stopPrank();
        (uint256 aliceStakeAmount, , ) = stakingContract.stakes(alice);
        (uint256 aliceLockRewardAmount, ) = stakingContract.lockedRewards(
            alice
        );
        assertEq(aliceStakeAmount, 100 ether);
        assertEq(aliceLockRewardAmount, 0);
    }

    function testUnstake() public {
        vm.startPrank(alice);

        (uint8 v, bytes32 r, bytes32 s) = _generatePermitSignature(alice);

        stakingContract.stakePermit(amountPermit100Ether, deadline, v, r, s);
        stakingContract.unstake(50 ether);
        vm.stopPrank();

        (uint256 aliceStakeAmount, , ) = stakingContract.stakes(alice);
        assertEq(aliceStakeAmount, 50 ether);
        assertEq(rntToken.balanceOf(alice), 950 ether);
    }

    function testClaimReward() public {
        vm.startPrank(alice);
        (uint8 v, bytes32 r, bytes32 s) = _generatePermitSignature(alice);

        stakingContract.stakePermit(amountPermit100Ether, deadline, v, r, s);

        console.log(
            "block.timestamp + 0.1 days / 1 days:",
            (block.timestamp + 0.1 days) / 1 days
        );
        console.log(
            "block.timestamp + 0.1 days:",
            (block.timestamp + 0.1 days)
        );
        console.log("block.timestamp:", (block.timestamp));

        // Fast forward time by 1 day
        vm.warp(block.timestamp + 1 days);

        console.log("1 days:", 1 days);
        stakingContract.claimReward();
        vm.stopPrank();

        assertEq(esRntToken.balanceOf(alice), 100 ether);
    }

    function testConvertReward() public {
        vm.startPrank(alice);
        (uint8 v, bytes32 r, bytes32 s) = _generatePermitSignature(alice);

        stakingContract.stakePermit(amountPermit100Ether, deadline, v, r, s);

        // Fast forward time by 1 day
        vm.warp(block.timestamp + 1 days);
        stakingContract.claimReward();

        // Alice converts 50 esRNT to RNT
        stakingContract.convertReward(50 ether);
        vm.stopPrank();

        assertEq(rntToken.balanceOf(alice), 50 ether);
        assertEq(esRntToken.balanceOf(alice), 50 ether);
    }

    function _generatePermitSignature(
        address signer
    ) private view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                signer,
                address(stakingContract),
                amountPermit100Ether,
                nonce,
                deadline
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                rntToken.DOMAIN_SEPARATOR(),
                structHash
            )
        );
        (v, r, s) = vm.sign(alicePK, digest);
    }
}
