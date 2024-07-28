// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {InscriptionToken} from "./InscriptionToken.sol";

contract InscriptionFactoryV1 is UUPSUpgradeable {
    event TokenDeployed(address tokenAddress);

    function deployInscription(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint
    ) public returns (InscriptionToken newToken) {
        newToken = new InscriptionToken();
        newToken.initialize(symbol, totalSupply, perMint);
        emit TokenDeployed(address(newToken));
    }

    function mintInscription(address tokenAddr) public {
        InscriptionToken token = InscriptionToken(tokenAddr);
        token.mint(msg.sender);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
