// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC1363.sol";
import "./interfaces/IERC1363Receiver.sol";
import "./interfaces/IERC1363Spender.sol";

abstract contract ERC1363Guardian is IERC1363Receiver, IERC1363Spender {
    /**
     * @dev Emitted when a `value` amount of tokens `token` are moved from `from` to
     * this contract by `operator` using `transferAndCall` or `transferFromAndCall`.
     */
    event TokensReceived(
        address indexed token,
        address indexed operator,
        address indexed from,
        uint256 value,
        bytes data
    );

    /**
     * @dev Emitted when the allowance for token `token` of this contract for an `owner` is set by
     * a call to `approveAndCall`. `value` is the new allowance.
     */
    event TokensApproved(
        address indexed token,
        address indexed owner,
        uint256 value,
        bytes data
    );

    /*
     * @inheritdoc IERC1363Receiver
     */
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        // The ERC-1363 contract is always the caller.
        address token = msg.sender;

        emit TokensReceived(token, operator, from, value, data);

        _transferReceived(token, operator, from, value, data);

        return this.onTransferReceived.selector;
    }

    /*
     * @inheritdoc IERC1363Spender
     */
    function onApprovalReceived(
        address owner,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        // The ERC-1363 contract is always the caller.
        address token = msg.sender;

        emit TokensApproved(token, owner, value, data);

        _approvalReceived(token, owner, value, data);

        return this.onApprovalReceived.selector;
    }

    /**
     * @dev Called after validating a `onTransferReceived`. Implement this method to make your stuff within your contract.
     * @param token The address of the token that was received.
     * @param operator The address which called `transferAndCall` or `transferFromAndCall` function.
     * @param from The address which are tokens transferred from.
     * @param value The amount of tokens transferred.
     * @param data Additional data with no specified format.
     */
    function _transferReceived(
        address token,
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) internal virtual;

    /**
     * @dev Called after validating a `onApprovalReceived`. Implement this method to make your stuff within your contract.
     * @param token The address of the token that was approved.
     * @param owner The address which called `approveAndCall` function and previously owned the tokens.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format.
     */
    function _approvalReceived(
        address token,
        address owner,
        uint256 value,
        bytes calldata data
    ) internal virtual;
}

/**
 * @title TokenBankV1 is skipping the approve step from ERC20 and deposit
 * directly from ERC20 by user calling the `transferAndCall` function.
 * This contract can receive different ERC20 tokens to deposit.
 * @author TaylorLi
 * @notice
 */
contract TokenBankV1 is ERC1363Guardian {
    // user => token:balance
    mapping(address => mapping(address => uint256)) public userTokenBalance;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);

    constructor() {}

    function withdraw(address token, uint256 amount) public {
        require(amount > 0, "Insufficient withdraw amount");
        require(
            userTokenBalance[msg.sender][token] >= amount,
            "Insufficient balance"
        );

        userTokenBalance[msg.sender][token] -= amount;
        IERC20 erc20Token = IERC20(token);
        require(
            erc20Token.transfer({recipient: msg.sender, amount: amount}),
            "Token transfer failed"
        );

        emit Withdraw(msg.sender, token, amount);
    }

    function _transferReceived(
        address token,
        address /*operator*/,
        address from,
        uint256 value,
        bytes calldata /*data*/
    ) internal virtual override {
        _deposit(token, from, value);
    }

    function _approvalReceived(
        address token,
        address owner,
        uint256 value,
        bytes calldata /*data*/
    ) internal virtual override {
        IERC20(token).transferFrom(owner, address(this), value);
        _deposit(token, owner, value);
    }

    function _deposit(address token, address from, uint256 amount) internal {
        require(IERC1363(token).supportsInterface(type(IERC1363).interfaceId));
        require(amount > 0, "Insufficient deposit amount");

        userTokenBalance[from][token] += amount;

        emit Deposit(token, token, amount);
    }
}
