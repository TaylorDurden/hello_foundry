// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/Script.sol";

import {TokenPermit} from "../src/ERC20/ERC20Permit.sol";
import {MyNFT} from "../src/ERC721/MyNFT.sol";
import {NFTMarketPermit} from "../src/app/NFTMarketPermit.sol";

contract DeployNFTMarket is Script {
    function run() external {
        vm.startBroadcast();

        // deploy
        // TokenPermit tokenPermit = new TokenPermit("MuMuToken", "MMTK");
        MyNFT nft = new MyNFT("MuMuNFT", "MMNFT");
        // NFTMarketPermit nftMarketPermit = new NFTMarketPermit();

        // get deployed addresses
        // address tokenPermitAddress = address(tokenPermit);
        address nftAddress = address(nft);
        // address nftMarketPermitAddress = address(nftMarketPermit);

        // build the output of addresses
        string memory content = string(
            abi.encodePacked(
                // "TokenPermit: ",
                // vm.toString(tokenPermitAddress),
                // "\n",
                "MyNFT: ",
                vm.toString(nftAddress),
                "\n"
                // "NFTMarketPermit: ",
                // vm.toString(nftMarketPermitAddress),
                // "\n"
            )
        );

        // write to file
        vm.writeFile("nftmarket_deployment.txt", content);

        vm.stopBroadcast();
    }
}
