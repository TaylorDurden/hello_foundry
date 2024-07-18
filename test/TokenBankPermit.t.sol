// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {TokenPermit} from "../src/ERC20/ERC20Permit.sol";
import {TokenBankPermit} from "../src/TokenBankV2.sol";
import {SigUtils} from "../src/utils/SignUtils.sol";

/**
 * @dev Permit deadline has expired.
 */
error ERC2612ExpiredSignature(uint256 deadline);

/**
 * @dev Mismatched signature.
 */
error ERC2612InvalidSigner(address signer, address owner);

contract TokenBankPermitTest is Test {
    TokenPermit token;
    TokenBankPermit tokenBank;

    SigUtils sigUtils;

    uint256 internal ownerPrivateKey;
    uint256 internal invalidDepositerPrivateKey;

    address internal owner;
    address internal invalidDepositer;

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        (owner, ownerPrivateKey) = makeAddrAndKey("owner");
        (invalidDepositer, invalidDepositerPrivateKey) = makeAddrAndKey(
            "spender"
        );

        vm.prank(owner);
        token = new TokenPermit("MyToken", "MTK");
        tokenBank = new TokenBankPermit(token);

        sigUtils = new SigUtils(token.DOMAIN_SEPARATOR());
    }

    function test_deposit_permit_ok() public {
        uint256 amount = 2 * 1e18;
        uint256 deadline = 1 days;
        _assert_deposit_permit(amount, deadline, address(tokenBank));
    }

    function testFuzz_token_balance(uint256 amount, uint256 deadline) public {
        vm.assume(amount > 0 ether && amount < 1000 ether);
        vm.assume(deadline > 0 && deadline < 1000);
        _assert_deposit_permit(amount, deadline, address(tokenBank));
    }

    function invariant_tokenbank_balance_allowance_is_0() public {
        assertEq(token.balanceOf(address(tokenBank)), 0);
        assertEq(token.allowance(owner, address(tokenBank)), 0);
    }

    function test_should_error_ERC2612InvalidSigner() public {
        address _spender = address(this);
        uint256 _amount = 1e18;
        uint256 _deadline = 1 days;
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: _spender,
            value: _amount,
            nonce: token.nonces(owner),
            deadline: _deadline
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        vm.expectRevert();
        vm.prank(invalidDepositer);
        tokenBank.permitDeposit(_amount, _deadline, v, r, s);
    }

    function test_should_error_ERC2612ExpiredSignature() public {
        address _spender = address(this);
        uint256 _amount = 1e18;
        uint256 _deadline = 2 days;
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: _spender,
            value: _amount,
            nonce: token.nonces(owner),
            deadline: _deadline
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        vm.expectRevert(
            abi.encodeWithSelector(ERC2612ExpiredSignature.selector, 0 days)
        );
        vm.prank(owner);
        tokenBank.permitDeposit(_amount, 0 days, v, r, s);
    }

    function _assert_deposit_permit(
        uint256 _amount,
        uint256 _deadline,
        address _spender
    ) private {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: _spender,
            value: _amount,
            nonce: token.nonces(owner),
            deadline: _deadline
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        uint256 ownerBalanceBefore = token.balanceOf(owner);
        uint256 spenderBalanceBefore = token.balanceOf(_spender);
        uint256 allowanceBefore = token.allowance(owner, _spender);

        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, _spender, _amount);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, _spender, _amount);
        tokenBank.permitDeposit(_amount, _deadline, v, r, s);
        uint256 ownerBalanceAfter = token.balanceOf(owner);
        uint256 spenderBalanceAfter = token.balanceOf(_spender);
        uint256 allowanceAfter = token.allowance(owner, _spender);
        assertEq(ownerBalanceBefore - _amount, ownerBalanceAfter);
        assertEq(spenderBalanceBefore + _amount, spenderBalanceAfter);
        assertEq(tokenBank.userTokenBalance(owner, address(token)), _amount);
        assertEq(allowanceBefore, allowanceAfter);
        assertEq(allowanceBefore, 0);
        assertEq(allowanceBefore, 0);
    }
}
