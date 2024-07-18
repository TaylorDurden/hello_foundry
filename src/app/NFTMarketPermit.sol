// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {NFTMarket} from "./NFTMarket.sol";

contract NFTMarketPerimit is NFTMarket, Ownable, EIP712 {
    mapping(address => bool) public whiteList;
    address immutable WHITE_LIST_SIGNER;

    string private constant SIGNING_DOMAIN = "NFT-Market";
    string private constant SIGNATURE_VERSION = "1";

    bytes private constant PERMIT_SELL_TYPE_HASH =
        "PermitSell(address seller,address nft,uint256 tokenId,address token,uint256 price)";
    bytes private constant WHITE_LIST_TYPE_HASH =
        "WhiteList(address signer, address user)";

    error InvalidWhiteListSigner(address signer);
    error InvalidListingSigner(address signer);

    struct SellListing {
        address seller;
        address nft;
        uint256 tokenId;
        address token;
        uint256 price;
        uint256 deadline;
    }

    struct WhiteList {
        address owner;
        address user;
    }

    constructor()
        Ownable(msg.sender)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        WHITE_LIST_SIGNER = msg.sender;
    }

    function permitBuy(
        SellListing calldata sellListing,
        bytes calldata signatureWhiteList,
        bytes calldata signatureSellListing,
        bytes calldata signatureEIP2612
    ) public {
        _verifyWhiteListSignature(
            signatureWhiteList,
            WhiteList(owner(), msg.sender)
        );
        _checkListing(sellListing.nft, sellListing.tokenId);

        _verifySellListingSignature(signatureSellListing, sellListing);
        delete userNFTListing[sellListing.nft][sellListing.tokenId];
        // Decode and verify ERC20 permit signature
        _permitTokenTranfer(signatureEIP2612, sellListing);

        IERC721(sellListing.nft).transferFrom(
            address(this),
            msg.sender,
            sellListing.tokenId
        );
        emit NFTSold(
            msg.sender,
            sellListing.nft,
            sellListing.tokenId,
            sellListing.price
        );
    }

    function listPermit(
        SellListing calldata sellListing,
        bytes memory signatureSellListing
    ) public {
        // Ensure the signature is not expired
        require(
            block.timestamp <= sellListing.deadline,
            "ERC721 permit signature expired"
        );

        _verifySellListingSignature(signatureSellListing, sellListing);

        // Transfer the NFT from the owner to the marketplace contract
        IERC721(sellListing.nft).safeTransferFrom(
            msg.sender,
            address(this),
            sellListing.tokenId,
            abi.encode(sellListing.token, sellListing.price)
        );

        // Emit an event for the listing
        emit NFTListed(
            address(sellListing.nft),
            sellListing.tokenId,
            msg.sender,
            sellListing.price,
            sellListing.token
        );
    }

    function _verifyWhiteListSignature(
        bytes memory _signatureWhiteList,
        WhiteList memory _whiteList
    ) private view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(WHITE_LIST_TYPE_HASH),
                    _whiteList.owner,
                    _whiteList.user
                )
            )
        );
        address signer = ECDSA.recover(digest, _signatureWhiteList);
        if (signer != owner()) revert InvalidWhiteListSigner(signer);
    }

    function _checkListing(address nft, uint256 tokenId) private view {
        Listing memory listing = userNFTListing[address(nft)][tokenId];

        // Ensure the NFT is listed for sale
        if (listing.seller == address(0)) {
            revert NotListedForSale(tokenId);
        }
        // Ensure the NFT is listed for sale
        if (listing.seller == msg.sender) {
            revert NotAllowed(msg.sender, listing.seller, tokenId);
        }
    }

    function _verifySellListingSignature(
        bytes memory _signatureSellListing,
        SellListing memory _sellListing
    ) private view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(PERMIT_SELL_TYPE_HASH),
                    _sellListing.seller,
                    _sellListing.nft,
                    _sellListing.tokenId,
                    _sellListing.token,
                    _sellListing.price
                )
            )
        );
        address signer = ECDSA.recover(digest, _signatureSellListing);
        if (signer != _sellListing.seller) revert InvalidListingSigner(signer);
    }

    function _permitTokenTranfer(
        bytes memory _signatureEIP2612,
        SellListing memory _sellListing
    ) private {
        // Decode and verify ERC20 permit signature
        (uint8 v, bytes32 r, bytes32 s, uint256 deadline) = abi.decode(
            _signatureEIP2612,
            (uint8, bytes32, bytes32, uint256)
        );
        IERC20Permit(_sellListing.token).permit(
            msg.sender,
            address(this),
            _sellListing.price,
            deadline,
            v,
            r,
            s
        );

        // Transfer the payment tokens from the buyer to the seller
        bool transfered = IERC20(_sellListing.token).transferFrom(
            msg.sender,
            _sellListing.seller,
            _sellListing.price
        );
        if (!transfered)
            revert PaymentFailed(
                msg.sender,
                _sellListing.seller,
                _sellListing.price
            );
    }
}
