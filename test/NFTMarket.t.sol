// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IERC1363} from "../src/interfaces/IERC1363.sol";
import {NFTMarket} from "../src/app/NFTMarket.sol";
import {MyNFT} from "../src/ERC721/MyNFT.sol";
import {ERC1363, ERC20} from "../src/ERC1363/ERC1363.sol";

contract MockERC1363 is ERC1363 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000 * 10 ** 18);
    }
}

contract NFTMarketTest is Test {
    MyNFT myNFT1;
    MyNFT myNFT2;
    MockERC1363 tokenA;
    NFTMarket nftMarket;
    uint256 tokenId1;
    uint256 tokenId2;
    uint256 tokenId1Price = 1e18;
    uint256 tokenId2Price = 2e18;

    address owner;
    address user1;
    address user2;

    uint256 erc20Unit = 10 ** 18;

    function setUp() public {
        myNFT1 = new MyNFT("MuMu", "MMT");
        myNFT2 = new MyNFT("Taylor", "TTT");
        tokenA = new MockERC1363("TokenA", "TA");
        nftMarket = new NFTMarket(tokenA);

        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        myNFT1.mint(user1);
        tokenId1 = 0;
        myNFT1.mint(user2);
        tokenId2 = 0;

        tokenA.transfer(user1, 10e18);
        tokenA.transfer(user2, 10e18);
    }

    function test_list_listing_info_from_ERC721_safeTransferFrom() public {
        vm.startPrank(user1);
        myNFT1.approve(address(nftMarket), tokenId1);
        nftMarket.list(myNFT1, tokenId1, tokenId1Price);
        (address seller1, uint256 price1) = nftMarket.getTokenSellInfo(
            tokenId1,
            myNFT1
        );
        vm.stopPrank();

        // nftmarket.onTransferReceived should list the transfered nft to the listing
        assertEq(seller1, user1);
        assertEq(price1, tokenId1Price);

        // nft transfered to the nftmarket after nftContract.safeTransferFrom
        assertEq(myNFT1.ownerOf(tokenId1), address(nftMarket));
        // nft token approval cleared for the nftmarket after nftContract.safeTransferFrom
        assertEq(myNFT1.getApproved(tokenId1), address(0x0));
    }

    function test_buy_nft_with_token_transfer_directly() public {
        vm.startPrank(user1);
        myNFT1.approve(address(nftMarket), tokenId1);
        nftMarket.list(myNFT1, tokenId1, tokenId1Price);
        (address seller1, uint256 price1) = nftMarket.getTokenSellInfo(
            tokenId1,
            myNFT1
        );
        assertEq(seller1, user1);
        assertEq(price1, tokenId1Price);
        vm.stopPrank();

        uint256 user1BalanceBeforeNFTSold = tokenA.balanceOf(user1);
        vm.startPrank(user2);
        nftMarket.buy(myNFT1, tokenId1, tokenA);
        vm.stopPrank();

        // expect the nftMarket tranfer the token to the user1 directly
        assertEq(
            tokenA.balanceOf(user1),
            user1BalanceBeforeNFTSold + tokenId1Price
        );

        // transfert the nft to the user2
        assertEq(myNFT1.balanceOf(user1), 0);
        assertEq(myNFT1.balanceOf(user2), 1);
        assertEq(myNFT1.ownerOf(tokenId1), user2);

        (address seller1Sold, uint256 price1Sold) = nftMarket.getTokenSellInfo(
            tokenId1,
            myNFT1
        );
        assertEq(seller1Sold, address(0x0));
        assertEq(price1Sold, 0);
    }
}
