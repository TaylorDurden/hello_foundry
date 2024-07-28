// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {InscriptionToken} from "./InscriptionToken.sol";

// next comment is required, ref: https://github.com/OpenZeppelin/openzeppelin-foundry-upgrades?tab=readme-ov-file
/// @custom:oz-upgrades-from InscriptionFactoryV1
contract InscriptionFactoryV2 is UUPSUpgradeable {
    bytes32 private constant IMPLEMENTATION_SLOT =
        bytes32(uint(keccak256("eip1967.proxy.implementation")) - 1);
    event TokenDeployed(address tokenAddress);
    error InsufficientFund2Mint(uint256 price);
    uint256 price;
    address tokenAddress;

    function deployInscription(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 _price
    ) public returns (address newToken) {
        newToken = Clones.clone(tokenAddress);
        InscriptionToken(newToken).initialize(symbol, totalSupply, perMint);
        price = _price * perMint;
        emit TokenDeployed(address(newToken));
    }

    function mintInscription(address tokenAddr) public payable {
        // if (msg.value < price) revert InsufficientFund2Mint(msg.value);
        InscriptionToken(tokenAddr).mint(msg.sender);
    }

    function setERC20TokenAddr(address _tokenAddr) public {
        tokenAddress = _tokenAddr;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {
        // ERC1967Utils.(newImplementation, "");
    }
}
