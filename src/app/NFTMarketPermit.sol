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

    string private constant SIGNING_DOMAIN = "NFT-Market";
    string private constant SIGNATURE_VERSION = "1";

    constructor()
        Ownable(msg.sender)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {}

    function AddWhiteList(address user) public onlyOwner {
        if (!whiteList[user]) {
            whiteList[user] = true;
        }
    }

    function RemoveWhiteList(address user) public onlyOwner {
        if (whiteList[user]) {
            delete whiteList[user];
        }
    }

    function listPermit(bytes memory erc721Signature) public {}

    function permitBuy(
        IERC721 nft,
        uint256 tokenId,
        bytes calldata signatureForSellListing,
        bytes calldata signatureForERC20Approval
    ) public {
        Listing memory listing = userNFTListing[address(nft)][tokenId];

        // Ensure the NFT is listed for sale
        if (listing.seller == address(0)) {
            revert NotListedForSale(tokenId);
        }
        // Ensure the NFT is listed for sale
        if (listing.seller == msg.sender) {
            revert NotAllowed(msg.sender, listing.seller, tokenId);
        }

        // Decode and verify sell listing signature
        (uint8 vSell, bytes32 rSell, bytes32 sSell, uint256 deadlineSell) = abi
            .decode(
                signatureForSellListing,
                (uint8, bytes32, bytes32, uint256)
            );
        bytes32 digestSell = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("PermitSell(address nft,uint256 tokenId)"),
                    address(nft),
                    tokenId
                )
            )
        );
        address recoveredAddressSell = ECDSA.recover(
            digestSell,
            vSell,
            rSell,
            sSell
        );
        require(
            recoveredAddressSell == listing.seller,
            "Invalid sell listing signature"
        );

        // Decode and verify ERC20 permit signature
        (
            uint8 vERC20,
            bytes32 rERC20,
            bytes32 sERC20,
            uint256 deadlineERC20
        ) = abi.decode(
                signatureForERC20Approval,
                (uint8, bytes32, bytes32, uint256)
            );
        IERC20Permit(listing.token).permit(
            msg.sender,
            address(this),
            listing.price,
            deadlineERC20,
            vERC20,
            rERC20,
            sERC20
        );

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

        // Complete the sale
        delete userNFTListing[address(nft)][tokenId];
        nft.transferFrom(address(this), msg.sender, tokenId);

        emit NFTBought(msg.sender, address(nft), tokenId, listing.price);
    }

    function listPermit(
        IERC721 nft,
        uint256 tokenId,
        address token,
        uint256 price,
        bytes memory erc721Signature
    ) public {
        // Decode and verify the ERC721 permit signature
        (uint8 v, bytes32 r, bytes32 s, uint256 deadline) = abi.decode(
            erc721Signature,
            (uint8, bytes32, bytes32, uint256)
        );

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Permit(address owner,address nft,uint256 tokenId,uint256 deadline)"
                    ),
                    msg.sender,
                    address(nft),
                    tokenId,
                    deadline
                )
            )
        );

        address recoveredAddress = ECDSA.recover(digest, v, r, s);
        require(
            recoveredAddress == msg.sender,
            "Invalid ERC721 permit signature"
        );

        // Ensure the signature is not expired
        require(block.timestamp <= deadline, "ERC721 permit signature expired");

        // Transfer the NFT from the owner to the marketplace contract
        nft.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            abi.encode(token, price)
        );

        // Emit an event for the listing
        emit NFTListed(address(nft), tokenId, msg.sender, price, token);

        // Store the listing information
        userNFTListing[address(nft)][tokenId] = Listing(
            msg.sender,
            token,
            price
        );
    }
}
