// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ERC1363
 * @dev An extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * NOTE: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls `ERC1363Receiver::onTransferReceived` on `to`.
     * @param to The address to which tokens are being transferred.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls `ERC1363Receiver::onTransferReceived` on `to`.
     * @param to The address to which tokens are being transferred.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating the operation succeeded unless throwing.
     */
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls `ERC1363Receiver::onTransferReceived` on `to`.
     * @param from The address from which to send tokens.
     * @param to The address to which tokens are being transferred.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating the operation succeeded unless throwing.
     */
    function transferFromAndCall(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls `ERC1363Receiver::onTransferReceived` on `to`.
     * @param from The address from which to send tokens.
     * @param to The address to which tokens are being transferred.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating the operation succeeded unless throwing.
     */
    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the caller's tokens
     * and then calls `ERC1363Spender::onApprovalReceived` on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating the operation succeeded unless throwing.
     */
    function approveAndCall(
        address spender,
        uint256 value
    ) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the caller's tokens
     * and then calls `ERC1363Spender::onApprovalReceived` on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating the operation succeeded unless throwing.
     */
    function approveAndCall(
        address spender,
        uint256 value,
        bytes calldata data
    ) external returns (bool);
}
