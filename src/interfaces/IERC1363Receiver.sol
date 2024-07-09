// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title ERC1363Receiver
 * @dev Interface for any contract that wants to support `transferAndCall` or `transferFromAndCall` from ERC-1363 token contracts.
 */
interface IERC1363Receiver {
    /**
     * @dev Whenever ERC-1363 tokens are transferred to this contract via `ERC1363::transferAndCall` or `ERC1363::transferFromAndCall`
     * by `operator` from `from`, this function is called.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
     * (i.e. 0x88a7ca5c, or its own function selector).
     *
     * @param operator The address which called `transferAndCall` or `transferFromAndCall` function.
     * @param from The address which are tokens transferred from.
     * @param value The amount of tokens transferred.
     * @param data Additional data with no specified format.
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))` if transfer is allowed unless throwing.
     */
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
}
