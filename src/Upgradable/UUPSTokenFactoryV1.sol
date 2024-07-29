// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {InscriptionTokenV1} from "./InscriptionToken.sol";

contract InscriptionFactoryV1 is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    event TokenDeployed(address tokenAddress);

    function initialize() public initializer {
        __Ownable_init(msg.sender);
    }

    function deployInscription(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint
    ) public returns (InscriptionTokenV1 newToken) {
        newToken = new InscriptionTokenV1(symbol, symbol, totalSupply, perMint);
        emit TokenDeployed(address(newToken));
    }

    function mintInscription(address tokenAddr) public {
        InscriptionTokenV1 token = InscriptionTokenV1(tokenAddr);
        token.mint(msg.sender);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}
}
