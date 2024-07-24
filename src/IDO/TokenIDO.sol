// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RNTToken is ERC20, Ownable {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        _mint(msg.sender, 1e9 * 10 ** decimals());
    }

    function makeIDO(uint256 _amount, address _receiver) public onlyOwner {
        require(_amount <= balanceOf(msg.sender) / 10);
        transfer(_receiver, _amount);
    }
}

contract TokenIDO {
    uint256 public constant PRESALE_PRICE = 0.0001 ether;
    uint256 public constant PRESALE_TOKEN_AMOUNT = 1 * 10 ** 6;
    uint256 public constant MIN_PRESALE_TARGET =
        PRESALE_TOKEN_AMOUNT * PRESALE_PRICE;
    uint256 public constant MAX_PRESALE_TARGET = 2 * MIN_PRESALE_TARGET;
    uint256 public constant END_TIME = 30 days;
    IERC20 public immutable IDO_TOKEN;
    address public immutable OWNER;

    mapping(address => uint256) public balanceOf;

    error OnlyWhenIDOSucceed();
    error OnlyWhenIDOFailed();
    error OnlyWhenIDOActive();

    constructor(IERC20 tokenToIDO, address _owner) {
        IDO_TOKEN = tokenToIDO;
        OWNER = _owner;
    }

    function getEndTime() public pure returns (uint256) {
        return END_TIME;
    }

    modifier checkValue() {
        require(
            msg.value >= 0.01 ether &&
                msg.value <= 0.1 ether &&
                msg.value + address(this).balance <= MAX_PRESALE_TARGET
        );
        _;
    }

    modifier onlyIDOActive() {
        if (
            !(address(this).balance <= MAX_PRESALE_TARGET &&
                block.timestamp < END_TIME)
        ) {
            revert OnlyWhenIDOActive();
        }
        _;
    }

    modifier onlyIDOSucceed() {
        if (
            !(address(this).balance >= MIN_PRESALE_TARGET &&
                address(this).balance <= MAX_PRESALE_TARGET &&
                block.timestamp >= END_TIME)
        ) {
            revert OnlyWhenIDOSucceed();
        }
        _;
    }

    modifier onlyIDOFail() {
        if (
            !(address(this).balance < MIN_PRESALE_TARGET &&
                block.timestamp >= END_TIME)
        ) {
            revert OnlyWhenIDOFailed();
        }
        _;
    }

    function presale() public payable onlyIDOActive checkValue {
        balanceOf[msg.sender] += msg.value;
    }

    function claim() public onlyIDOSucceed {
        uint256 userClaim = (PRESALE_TOKEN_AMOUNT * balanceOf[msg.sender]) /
            address(this).balance;
        balanceOf[msg.sender] = 0;
        bool s = IDO_TOKEN.transfer(msg.sender, userClaim * 1 ether);
        require(s);
    }

    function withdraw() public onlyIDOSucceed {
        (bool s, ) = OWNER.call{value: address(this).balance}("");
        require(s, "Fail");
    }

    function refund() public onlyIDOFail {
        uint256 balance = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        (bool s, ) = msg.sender.call{value: balance}("");
        require(s);
    }
}
