// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC165, ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC1363Errors} from "../interfaces/IERC1363Errors.sol";
import "../interfaces/IERC1363.sol";
import "../interfaces/IERC1363Receiver.sol";
import "../interfaces/IERC1363Spender.sol";

abstract contract ERC1363 is ERC20, ERC165, IERC1363, IERC1363Errors {
    function transferAndCall(
        address to,
        uint256 value
    ) public virtual returns (bool) {
        return transferAndCall(to, value, "");
    }

    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) public virtual returns (bool) {
        if (!transfer(to, value)) {
            revert ERC1363TransferFailed(to, value);
        }
        _checkOnTransferReceived(msg.sender, to, value, data);
        return true;
    }

    function transferFromAndCall(
        address from,
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        return transferFromAndCall(from, to, value, "");
    }

    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) public virtual override returns (bool) {
        if (!transferFrom(from, to, value)) {
            revert ERC1363TransferFromFailed(from, to, value);
        }
        _checkOnTransferReceived(from, to, value, data);
        return true;
    }

    function approveAndCall(
        address spender,
        uint256 value
    ) public virtual override returns (bool) {
        return approveAndCall(spender, value, "");
    }

    function approveAndCall(
        address spender,
        uint256 value,
        bytes memory data
    ) public virtual override returns (bool) {
        if (!approve(spender, value)) {
            revert ERC1363ApproveFailed(spender, value);
        }
        _checkOnApprovalReceived(spender, value, data);
        return true;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1363).interfaceId;
    }

    /**
     * @dev Performs a call to {IERC1363Receiver-onTransferReceived} on a target address.
     * This will revert if the target doesn't implement the `IERC1363Receiver` interface or
     * if the target doesn't accept the token transfer or
     * if the target address is not a contract.
     *
     * @param from Address representing the previous owner of the given token amount.
     * @param to Target address that will receive the tokens.
     * @param value The amount of tokens to be transferred.
     * @param data Optional data to send along with the call.
     */
    function _checkOnTransferReceived(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) private {
        if (to.code.length == 0) {
            revert ERC1363InvalidReceiver(to);
        }

        try
            IERC1363Receiver(to).onTransferReceived(
                msg.sender,
                from,
                value,
                data
            )
        returns (bytes4 retval) {
            if (retval != IERC1363Receiver.onTransferReceived.selector) {
                revert ERC1363InvalidReceiver(to);
            }
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert ERC1363InvalidReceiver(to);
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Performs a call to `IERC1363Spender::onApprovalReceived` on a target address.
     * This will revert if the target doesn't implement the `IERC1363Spender` interface or
     * if the target doesn't accept the token approval or
     * if the target address is not a contract.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Optional data to send along with the call.
     */
    function _checkOnApprovalReceived(
        address spender,
        uint256 value,
        bytes memory data
    ) private {
        if (spender.code.length == 0) {
            revert ERC1363EOASpender(spender);
        }

        try
            IERC1363Spender(spender).onApprovalReceived(
                _msgSender(),
                value,
                data
            )
        returns (bytes4 retval) {
            if (retval != IERC1363Spender.onApprovalReceived.selector) {
                revert ERC1363InvalidSpender(spender);
            }
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert ERC1363InvalidSpender(spender);
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }
}
