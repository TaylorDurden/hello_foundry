// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract InscriptionTokenV2 is
    Initializable,
    OwnableUpgradeable,
    ERC20Upgradeable
{
    uint256 public perMint;

    function initialize(
        string memory symbol,
        uint256 totalSupply,
        uint256 _perMint
    ) public initializer {
        __ERC20_init(symbol, symbol);
        __Ownable_init(msg.sender);
        _mint(msg.sender, totalSupply);
        perMint = _perMint;
    }

    function mint(address to) external {
        _mint(to, perMint);
    }
}

contract InscriptionTokenV1 is ERC20, Ownable {
    uint256 public perMint;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _perMint
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        perMint = _perMint;
        _mint(msg.sender, _totalSupply);
    }

    function mint(address to) external {
        _mint(to, perMint);
    }
}
