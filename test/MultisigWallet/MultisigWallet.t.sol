// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/MultisigWallet/MultisigWallet.sol";

contract MultiSigWalletTest is Test {
  MultiSigWallet multiSigWallet;
  address[] owners;
  uint256 owner0PK;
  uint256 owner1PK;
  uint256 owner2PK;
  uint256 numConfirmationsRequired;

  function setUp() public {
    owners = new address[](3);
    (owners[0], owner0PK) = makeAddrAndKey("owner0");
    (owners[1], owner1PK) = makeAddrAndKey("owner1");
    (owners[2], owner2PK) = makeAddrAndKey("owner2");
    numConfirmationsRequired = 2;

    multiSigWallet = new MultiSigWallet(owners, numConfirmationsRequired);
    vm.deal(address(multiSigWallet), 100 ether);
  }

  function testSubmitTransaction() public {
    vm.startPrank(owners[0]);
    multiSigWallet.submitTransaction(address(0xabc), 1 ether, "");
    (address to, uint256 value, bytes memory data, bool executed, uint256 numConfirmations) = multiSigWallet
      .getTransaction(0);
    assertEq(to, address(0xabc));
    assertEq(value, 1 ether);
    assertEq(data, "");
    assertEq(executed, false);
    assertEq(numConfirmations, 0);
    vm.stopPrank();
  }

  function testConfirmTransaction() public {
    vm.startPrank(owners[0]);
    multiSigWallet.submitTransaction(address(0xabc), 1 ether, "");
    bytes32 txHash = multiSigWallet.getTransactionHash(0, address(0xabc), 1 ether, "");
    bytes memory signature = signTransaction(txHash, owner0PK);
    multiSigWallet.confirmTransaction(0, signature);
    (, , , , uint256 numConfirmations) = multiSigWallet.getTransaction(0);
    assertEq(numConfirmations, 1);
    vm.stopPrank();
  }

  function testExecuteTransaction() public {
    vm.startPrank(owners[0]);
    multiSigWallet.submitTransaction(address(0xabc), 1 ether, "");
    bytes32 txHash = multiSigWallet.getTransactionHash(0, address(0xabc), 1 ether, "");
    bytes memory signature1 = signTransaction(txHash, owner0PK);
    bytes memory signature2 = signTransaction(txHash, owner1PK);
    multiSigWallet.confirmTransaction(0, signature1);
    vm.stopPrank();
    vm.startPrank(owners[1]);
    multiSigWallet.confirmTransaction(0, signature2);
    multiSigWallet.executeTransaction(0);
    (, , , bool executed, ) = multiSigWallet.getTransaction(0);
    assertEq(executed, true);
    vm.stopPrank();
  }

  function signTransaction(bytes32 txHash, uint256 privateKey) private view returns (bytes memory) {
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", multiSigWallet.DOMAIN_SEPARATOR(), txHash));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
    bytes memory sellListingSignature = abi.encodePacked(r, s, v);
    return sellListingSignature;
  }
}
