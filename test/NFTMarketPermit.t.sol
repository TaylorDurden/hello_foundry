// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {NFTMarketPermit} from "../src/app/NFTMarketPermit.sol";
import {TokenPermit} from "../src/ERC20/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestNFT is ERC721 {
    constructor() ERC721("TestNFT", "TNFT") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract TestToken is TokenPermit {
    constructor() TokenPermit("TestToken", "TTK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract NFTMarketPermitTest is Test {
    NFTMarketPermit public market;
    TestNFT public nft;
    TestToken public token;

    address public owner;
    uint256 public ownerPK;
    address public seller;
    uint256 public sellerPK;
    address public buyer;
    uint256 public buyerPK;

    uint256 public tokenId;
    uint256 public nftPrice;
    uint256 public deadline;

    bytes32 public eip2612PermitTypeHash =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    function setUp() public {
        (owner, ownerPK) = makeAddrAndKey("owner");
        (seller, sellerPK) = makeAddrAndKey("seller");
        (buyer, buyerPK) = makeAddrAndKey("buyer");
        deadline = block.timestamp + 1 days;
        vm.prank(owner);
        market = new NFTMarketPermit();

        nft = new TestNFT();
        token = new TestToken();

        nft.mint(seller, 1);
        tokenId = 1;
        nftPrice = 10 ether;
        token.mint(buyer, 10000 ether);
    }

    // function testListPermit() public {
    //     bytes memory sellListingSignature = _getSellListingSignature();

    //     vm.prank(seller);
    //     market.listPermit(
    //         NFTMarketPermit.SellListing(
    //             seller,
    //             address(nft),
    //             1,
    //             address(token),
    //             1000 ether,
    //             deadline,
    //             market.nonces(owner)
    //         ),
    //         sellListingSignature
    //     );

    //     assertEq(nft.ownerOf(1), address(market));
    // }

    function testPermitBuy() public {
        // Setup: list the NFT
        bytes memory sellListingSignature = _getSellListingSignature();
        bytes memory whiteListSignature = _getWhiteListSignature();
        bytes memory eip2612Signature = _getEIP2612Signature();

        vm.startPrank(seller);
        nft.approve(address(market), tokenId);
        market.list(nft, tokenId, address(token), nftPrice);
        vm.stopPrank();

        vm.prank(buyer);
        market.permitBuy(
            NFTMarketPermit.SellListing(
                seller,
                address(nft),
                tokenId,
                address(token),
                nftPrice,
                deadline
            ),
            NFTMarketPermit.BuyPermit(deadline),
            whiteListSignature,
            sellListingSignature,
            eip2612Signature
        );

        assertEq(nft.ownerOf(1), buyer);
    }

    function _getEIP2612Signature() private view returns (bytes memory) {
        bytes32 eip2612Digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                TokenPermit(token).DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        eip2612PermitTypeHash,
                        buyer,
                        address(market),
                        nftPrice,
                        token.nonces(buyer),
                        deadline
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPK, eip2612Digest);
        bytes memory eip2612Signature = abi.encodePacked(r, s, v);
        return eip2612Signature;
    }

    function _getWhiteListSignature() private view returns (bytes memory) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                market.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(market.getWhiteListTypeHash(), buyer))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPK, digest);
        bytes memory whitelistSignature = abi.encodePacked(r, s, v);
        return whitelistSignature;
    }

    function _getSellListingSignature() private view returns (bytes memory) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                market.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        market.getPermitSellTypeHash(),
                        seller,
                        address(nft),
                        tokenId,
                        address(token),
                        nftPrice,
                        deadline,
                        market.nonces(owner)
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sellerPK, digest);
        bytes memory sellListingSignature = abi.encodePacked(r, s, v);
        return sellListingSignature;
    }

    function invariant_nftmarket_balance_allowance_is_0() public {
        assertEq(token.balanceOf(address(market)), 0);
        assertEq(token.allowance(owner, address(market)), 0);
    }
}
