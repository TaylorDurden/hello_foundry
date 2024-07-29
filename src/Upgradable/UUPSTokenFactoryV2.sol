// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {InscriptionTokenV2} from "./InscriptionToken.sol";

// next comment is required, ref: https://github.com/OpenZeppelin/openzeppelin-foundry-upgrades?tab=readme-ov-file
/// @custom:oz-upgrades-from InscriptionFactoryV1
contract InscriptionFactoryV2 is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    struct TokenInfo {
        uint256 price;
        address owner;
    }
    event TokenDeployed(address tokenAddress);
    error InvalidFund2Mint(uint256 price);
    address proxyTokenAddress;
    mapping(address => TokenInfo) tokens;

    function initialize() public initializer {}

    function setProxyToken(address _token) public {
        proxyTokenAddress = _token;
    }

    function deployInscription(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 _price
    ) public returns (address newToken) {
        newToken = Clones.clone(proxyTokenAddress);
        InscriptionTokenV2(newToken).initialize(symbol, totalSupply, perMint);
        tokens[address(newToken)] = TokenInfo({
            price: _price,
            owner: msg.sender
        });
        emit TokenDeployed(address(newToken));
    }

    function mintInscription(address tokenAddr) public payable {
        uint256 price = tokens[tokenAddr].price;
        if (msg.value != price) revert InvalidFund2Mint(msg.value);
        InscriptionTokenV2(tokenAddr).mint(msg.sender);
        (bool s, ) = tokens[tokenAddr].owner.call{value: msg.value}("");
        require(s);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}
}
