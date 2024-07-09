// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IERC1363Receiver.sol";
import "../interfaces/IERC1363Spender.sol";
import "../interfaces/IERC1363.sol";

abstract contract ERC1363 is ERC20, IERC1363 {
    // uint256 public totalSupply;
    // mapping(address => uint256) public balanceOf;
    // mapping(address => mapping(address => uint256)) public allowance;
    // string public name;
    // string public symbol;
    // uint8 public immutable decimals;

    // constructor(
    //     string memory _name,
    //     string memory _symbol,
    //     uint8 _decimals,
    //     uint256 _totalSupply
    // ) {
    //     name = _name;
    //     symbol = _symbol;
    //     decimals = _decimals;
    //     totalSupply = _totalSupply;
    //     balanceOf[msg.sender] = totalSupply;
    // }

    // function transfer(
    //     address recipient,
    //     uint256 amount
    // ) external returns (bool) {
    //     return _transfer(recipient, amount);
    // }

    // function _transfer(
    //     address recipient,
    //     uint256 amount
    // ) internal returns (bool) {
    //     require(balanceOf[msg.sender] >= amount, "Insufficient balance");

    //     balanceOf[msg.sender] -= amount;
    //     balanceOf[recipient] += amount;
    //     emit Transfer(msg.sender, recipient, amount);
    //     return true;
    // }

    // function approve(address spender, uint256 amount) external returns (bool) {
    //     return _approve(spender, amount);
    // }

    // function _approve(address spender, uint256 amount) internal returns (bool) {
    //     allowance[msg.sender][spender] = amount;
    //     emit Approval(msg.sender, spender, amount);
    //     return true;
    // }

    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 amount
    // ) external returns (bool) {
    //     require(balanceOf[from] >= amount, "Insufficient balance");
    //     require(allowance[from][msg.sender] >= amount, "Allowance exceeded");

    //     balanceOf[from] -= amount;
    //     balanceOf[to] += amount;
    //     allowance[from][msg.sender] -= amount;
    //     emit Transfer(from, to, amount);
    //     return true;
    // }

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1363InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the token `spender`. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1363InvalidSpender(address spender);

    /**
     * @dev Indicates a failure within the {transfer} part of a transferAndCall operation.
     * @param receiver Address to which tokens are being transferred.
     * @param value Amount of tokens to be transferred.
     */
    error ERC1363TransferFailed(address receiver, uint256 value);

    /**
     * @dev Indicates a failure within the {transferFrom} part of a transferFromAndCall operation.
     * @param sender Address from which to send tokens.
     * @param receiver Address to which tokens are being transferred.
     * @param value Amount of tokens to be transferred.
     */
    error ERC1363TransferFromFailed(
        address sender,
        address receiver,
        uint256 value
    );

    /**
     * @dev Indicates a failure within the {approve} part of a approveAndCall operation.
     * @param spender Address which will spend the funds.
     * @param value Amount of tokens to be spent.
     */
    error ERC1363ApproveFailed(address spender, uint256 value);

    function transferAndCall(address to, uint256 value) public returns (bool) {
        transferAndCall(to, value, "");
    }

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) public override returns (bool) {
        _checkOnTransferReceived(msg.sender, to, value, data);
    }

    function transferFromAndCall(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        transferFromAndCall(from, to, value, "");
    }

    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes calldata data
    ) public override returns (bool) {
        if (!transferFrom(from, to, value)) {
            revert ERC1363TransferFromFailed(from, to, value);
        }
        _checkOnTransferReceived(from, to, value, data);
        return true;
    }

    function approveAndCall(
        address spender,
        uint256 value
    ) public override returns (bool) {
        approveAndCall(spender, value, "");
    }

    function approveAndCall(
        address spender,
        uint256 value,
        bytes calldata data
    ) public override returns (bool) {
        if (!approve(spender, value)) {
            revert ERC1363ApproveFailed(spender, value);
        }
        _checkOnApprovalReceived(spender, value, data);
        return true;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
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
