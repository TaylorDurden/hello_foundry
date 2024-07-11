// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IERC1363} from "../interfaces/IERC1363.sol";
import {IERC1363Receiver} from "../interfaces/IERC1363Receiver.sol";
import {MyNFT} from "../ERC721/MyNFT.sol";
import {ERC1363, IERC20} from "../ERC1363/ERC1363.sol";

contract NFTMarket is IERC721Receiver {
    IERC20 public payableToken;

    // user => token:balance
    struct NFTListing {
        address seller;
        uint256 price;
    }
    mapping(address nftToken => mapping(uint256 tokenId => NFTListing))
        public userNFTListing;

    event NFTListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event NFTBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event NFTDelisted(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    constructor(IERC20 _payableToken) {
        payableToken = _payableToken;
    }

    function list(
        IERC721 nft,
        uint256 tokenId,
        uint256 price
    ) public returns (bool) {
        nft.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            abi.encode(price)
        );

        return true;
    }

    function buy(
        IERC721 nft,
        uint256 tokenId,
        IERC20 erc20
    ) public returns (bool) {}

    function onERC721Received(
        address /*operator*/,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        address seller = from;
        uint256 price = abi.decode(data, (uint256));
        address nft = msg.sender;

        userNFTListing[nft][tokenId] = NFTListing(seller, price);
        return this.onERC721Received.selector;
    }

    function getTokenSellInfo(
        uint256 tokenId,
        IERC721 erc721
    ) public view returns (address, uint256) {
        return (
            userNFTListing[address(erc721)][tokenId].seller,
            userNFTListing[address(erc721)][tokenId].price
        );
    }
}
