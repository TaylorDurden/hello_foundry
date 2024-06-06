// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract SignatureTest is Test {
    function testSignature() public {
        uint256 privateKey = 123;
        address publicKey = vm.addr(privateKey);

        bytes32 msgHash = keccak256("secret message");

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        address signer = ecrecover(msgHash, v, r, s);
        assertEq(signer, publicKey);

        bytes32 invalidMsgHash = keccak256("invalid message");
        signer = ecrecover(invalidMsgHash, v, r, s);

        assertTrue(signer != publicKey);
    }
}
