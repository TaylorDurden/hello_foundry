// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {NFTMarket} from "./NFTMarket.sol";

contract NFTMarketPermit is Ownable, EIP712, Nonces {
    mapping(bytes32 => bool) public orderFullfiled;
    string private constant SIGNING_DOMAIN = "NFT-Market-Permit";
    string private constant SIGNATURE_VERSION = "1";

    bytes32 private constant PERMIT_SELL_TYPE_HASH =
        keccak256(
            "PermitSell(address seller,address nft,address token,uint256 price,uint256 deadline)"
        );
    bytes32 private constant WHITE_LIST_TYPE_HASH =
        keccak256("WhiteList(address user)");

    error InvalidWhiteListSigner(address signer);
    error InvalidListingSigner(address signer);
    error SignatureExpired(bytes signature);
    error OrderAlreadyFullfiled(address nft, uint256 tokenId);
    error PaymentFailed(address buyer, address seller, uint256 price);

    event NFTListed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address seller,
        uint256 price,
        address token
    );
    event NFTSold(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    struct SellListing {
        address seller;
        address nft;
        uint256 tokenId;
        address token;
        uint256 price;
        uint256 deadline;
    }

    struct BuyPermit {
        uint256 deadline;
    }

    struct WhiteList {
        address user;
    }

    constructor()
        Ownable(msg.sender)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {}

    function getPermitSellTypeHash() public pure returns (bytes32) {
        return PERMIT_SELL_TYPE_HASH;
    }

    function getWhiteListTypeHash() public pure returns (bytes32) {
        return WHITE_LIST_TYPE_HASH;
    }

    function nonces(
        address owner
    ) public view virtual override(Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    function permitBuy(
        SellListing calldata sellListing,
        BuyPermit calldata buyPermit,
        bytes calldata signatureWhiteList,
        bytes calldata signatureSellListing,
        bytes calldata signatureEIP2612
    ) public payable {
        _verifyWhiteListSignature(signatureWhiteList);

        _verifySellListingSignature(signatureSellListing, sellListing);
        // Decode and verify ERC20 permit signature
        _permitTokenTranfer(signatureEIP2612, sellListing, buyPermit);

        IERC721(sellListing.nft).transferFrom(
            sellListing.seller,
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

    function _verifyWhiteListSignature(
        bytes memory _signatureWhiteList
    ) private view {
        WhiteList memory _whiteList = WhiteList({user: msg.sender});
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(WHITE_LIST_TYPE_HASH, _whiteList.user))
        );
        address signer = ECDSA.recover(digest, _signatureWhiteList);
        if (signer != owner()) revert InvalidWhiteListSigner(signer);
    }

    function _verifySellListingSignature(
        bytes memory _signatureSellListing,
        SellListing memory _sellListing
    ) private {
        require(_sellListing.deadline >= block.timestamp, "");
        bytes32 orderHash = keccak256(
            abi.encode(
                _sellListing.nft,
                _sellListing.tokenId,
                _sellListing.token,
                _sellListing.price,
                _sellListing.deadline
            )
        );
        if (orderFullfiled[orderHash])
            revert OrderAlreadyFullfiled(
                _sellListing.nft,
                _sellListing.tokenId
            );
        orderFullfiled[orderHash] = true;

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    PERMIT_SELL_TYPE_HASH,
                    _sellListing.seller,
                    _sellListing.nft,
                    _sellListing.token,
                    _sellListing.price,
                    _sellListing.deadline
                )
            )
        );

        address signer = ECDSA.recover(digest, _signatureSellListing);
        if (signer != _sellListing.seller) revert InvalidListingSigner(signer);
    }

    function _permitTokenTranfer(
        bytes memory _signatureEIP2612,
        SellListing calldata _sellListing,
        BuyPermit calldata buyPermit
    ) private {
        // Decode and verify ERC20 permit signature
        bytes32 r;
        bytes32 s;
        uint8 v;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        /// @solidity memory-safe-assembly
        assembly {
            r := mload(add(_signatureEIP2612, 0x20))
            s := mload(add(_signatureEIP2612, 0x40))
            v := byte(0, mload(add(_signatureEIP2612, 0x60)))
        }
        if (_sellListing.token == address(0)) {
            (bool success, ) = _sellListing.seller.call{
                value: _sellListing.price
            }("");
            require(success);
        } else {
            IERC20Permit(_sellListing.token).permit(
                msg.sender,
                address(this),
                _sellListing.price,
                buyPermit.deadline,
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
}
