// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IERC1363} from "../interfaces/IERC1363.sol";
import {IERC1363Receiver} from "../interfaces/IERC1363Receiver.sol";
import {MyNFT} from "../ERC721/MyNFT.sol";
import {ERC1363, IERC20} from "../ERC1363/ERC1363.sol";

interface INFTMarketEvents {
    event NFTListed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address seller,
        uint256 price,
        address token
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
}

interface INFTMarketErrors {
    error PaymentFailed(address buyer, address seller, uint256 price);
    error NotListedForSale(uint256 tokenId);
    error NotAllowed(address buyer, address seller, uint256 tokenId);
}

contract NFTMarket is IERC721Receiver, INFTMarketEvents, INFTMarketErrors {
    struct Listing {
        address seller;
        address token;
        uint256 price;
    }
    mapping(address nftToken => mapping(uint256 tokenId => Listing))
        public userNFTListing;

    constructor() {}

    function list(
        IERC721 nft,
        uint256 tokenId,
        address token,
        uint256 price
    ) public {
        nft.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            abi.encode(token, price)
        );
        // Emit an event for the listing
        emit NFTListed(address(nft), tokenId, msg.sender, price, token);
    }

    function buy(IERC721 nft, uint256 tokenId) public returns (bool) {
        Listing memory listing = userNFTListing[address(nft)][tokenId];

        // Ensure the NFT is listed for sale
        if (listing.seller == address(0)) {
            revert NotListedForSale(tokenId);
        }
        // Ensure the NFT is listed for sale
        if (listing.seller == msg.sender) {
            revert NotAllowed(msg.sender, listing.seller, tokenId);
        }
        // Transfer the payment tokens from the buyer to the seller
        if (
            !IERC20(listing.token).transferFrom(
                msg.sender,
                listing.seller,
                listing.price
            )
        ) {
            revert PaymentFailed(msg.sender, listing.seller, listing.price);
        }

        delete userNFTListing[address(nft)][tokenId];
        nft.transferFrom(address(this), msg.sender, tokenId);

        return true;
    }

    function onERC721Received(
        address /*operator*/,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        address nft = msg.sender;
        require(nft.code.length > 0, "Only contract");
        (address token, uint256 price) = abi.decode(data, (address, uint256));
        // if (price == 0 || token == address(0)) {
        //     return this.onERC721Received.selector;
        // }
        address seller = from;

        userNFTListing[nft][tokenId] = Listing(seller, token, price);
        return this.onERC721Received.selector;
    }

    function getTokenSellInfo(
        uint256 tokenId,
        IERC721 erc721
    ) public view returns (address, address, uint256) {
        return (
            userNFTListing[address(erc721)][tokenId].seller,
            userNFTListing[address(erc721)][tokenId].token,
            userNFTListing[address(erc721)][tokenId].price
        );
    }
}
