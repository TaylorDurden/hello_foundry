// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Errors, IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {IERC1363} from "../src/interfaces/IERC1363.sol";
import {NFTMarket, INFTMarketEvents, INFTMarketErrors} from "../src/app/NFTMarket.sol";
import {MyNFT} from "../src/ERC721/MyNFT.sol";
import {ERC1363, ERC20} from "../src/ERC1363/ERC1363.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000 * 10 ** 18);
    }
}

contract NFTMarketTest is
    Test,
    INFTMarketEvents,
    INFTMarketErrors,
    IERC20Errors,
    IERC721Errors
{
    MyNFT myNFT1;
    MyNFT myNFT2;
    MockERC20 tokenA;
    MockERC20 tokenB;
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
        tokenA = new MockERC20("TokenA", "TA");
        tokenB = new MockERC20("TokenA", "TB");
        nftMarket = new NFTMarket();

        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        myNFT1.mint(user1, "");
        tokenId1 = 0;
        myNFT1.mint(user2, "");
        tokenId2 = 0;

        tokenA.transfer(user1, 10e18);
        tokenA.transfer(user2, 10e18);

        tokenB.transfer(user2, 10e18);
        tokenB.transfer(user1, 10e18);
    }

    function test_list_listing_info_from_ERC721_safeTransferFrom() public {
        listNFT();
    }

    function test_buy_nft_with_token_transfer_directly() public {
        listNFT();
        uint256 user2NFTBalanceBeforeBuy = myNFT1.balanceOf(user2);
        uint256 user1BalanceBeforeNFTSold = tokenB.balanceOf(user1);
        uint256 user2BalanceBeforeNFTSold = tokenB.balanceOf(user2);

        vm.startPrank(user2);
        tokenB.approve(address(nftMarket), tokenId1Price);
        nftMarket.buy(myNFT1, tokenId1);
        vm.stopPrank();

        // expect the nftMarket tranfer the token to the user1 directly
        assertEq(
            tokenB.balanceOf(user1),
            user1BalanceBeforeNFTSold + tokenId1Price
        );
        assertEq(
            tokenB.balanceOf(user2),
            user2BalanceBeforeNFTSold - tokenId1Price
        );

        // transfert the nft to the user2
        assertEq(myNFT1.balanceOf(user1), 0);
        assertEq(myNFT1.balanceOf(user2), user2NFTBalanceBeforeBuy + 1);
        assertEq(myNFT1.ownerOf(tokenId1), user2);

        // ensure the nftContract.safeTransferFrom callback not listing the nft
        (address seller1Sold, address sellToken, uint256 price1Sold) = nftMarket
            .getTokenSellInfo(tokenId1, myNFT1);
        assertEq(seller1Sold, address(0));
        assertEq(sellToken, address(0));
        assertEq(price1Sold, 0);
    }

    function test_not_allow_buy_self_nft() public {
        vm.startPrank(user1);
        myNFT1.approve(address(nftMarket), tokenId1);
        nftMarket.list(myNFT1, tokenId1, address(tokenB), tokenId1Price);

        (address seller, , ) = nftMarket.getTokenSellInfo(tokenId1, myNFT1);

        tokenB.approve(address(nftMarket), tokenId1Price);
        vm.expectRevert(
            abi.encodeWithSelector(NotAllowed.selector, user1, seller, tokenId1)
        );
        nftMarket.buy(myNFT1, tokenId1);
        vm.stopPrank();
    }

    function testBuyWithIncorrectPaymentFailure() public {
        vm.startPrank(user1);
        myNFT1.approve(address(nftMarket), tokenId1);
        nftMarket.list(myNFT1, tokenId1, address(tokenA), tokenId1Price);
        vm.stopPrank();

        vm.startPrank(user2);
        uint256 incorrectPrice = tokenId1Price - 1;
        tokenA.approve(address(nftMarket), incorrectPrice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20InsufficientAllowance.selector,
                address(nftMarket),
                incorrectPrice,
                tokenId1Price
            )
        );
        nftMarket.buy(myNFT1, tokenId1);
        vm.stopPrank();
    }

    function test_not_allow_buy_sold_nft() public {
        vm.startPrank(user1);
        myNFT1.approve(address(nftMarket), tokenId1);
        nftMarket.list(myNFT1, tokenId1, address(tokenB), tokenId1Price);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(nftMarket), tokenId1Price);
        nftMarket.buy(myNFT1, tokenId1);
        vm.expectRevert(abi.encodeWithSelector(NotForSale.selector, tokenId1));
        nftMarket.buy(myNFT1, tokenId1);
        vm.stopPrank();
    }

    function testListFailure() public {
        vm.startPrank(user2);
        vm.expectRevert(
            abi.encodeWithSelector(ERC721InvalidApprover.selector, user2)
        );
        myNFT1.approve(address(nftMarket), tokenId1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC721InsufficientApproval.selector,
                address(nftMarket),
                tokenId1
            )
        );
        nftMarket.list(myNFT1, tokenId1, address(tokenA), tokenId1Price);
        vm.stopPrank();
    }

    function testInvariant_TokenBalance() public {
        uint256 nftMarketBalanceA = tokenA.balanceOf(address(nftMarket));
        uint256 nftMarketBalanceB = tokenB.balanceOf(address(nftMarket));
        assertEq(nftMarketBalanceA, 0);
        assertEq(nftMarketBalanceB, 0);
    }

    function testFuzzListAndBuy(uint256 price) public {
        vm.assume(price > 0.01 ether && price < 10000 ether);

        vm.startPrank(user1);
        myNFT1.approve(address(nftMarket), tokenId1);
        nftMarket.list(myNFT1, tokenId1, address(tokenA), price);
        vm.stopPrank();

        // ensure that buyer balance always >= price
        uint256 user2Balance = tokenA.balanceOf(user2);
        vm.assume(user2Balance >= price);

        vm.startPrank(user2);
        uint256 user2BalanceBefore = tokenA.balanceOf(user2);
        uint256 user1BalanceBefore = tokenA.balanceOf(user1);
        tokenA.approve(address(nftMarket), price);
        nftMarket.buy(myNFT1, tokenId1);
        vm.stopPrank();

        assertEq(tokenA.balanceOf(user1), user1BalanceBefore + price);
        assertEq(tokenA.balanceOf(user2), user2BalanceBefore - price);
        assertEq(myNFT1.ownerOf(tokenId1), user2);
    }

    function testOnERC721Received() public {
        bytes memory data = abi.encode(address(tokenA), tokenId1Price);
        vm.startPrank(user1);
        myNFT1.safeTransferFrom(user1, address(nftMarket), tokenId1, data);
        vm.stopPrank();

        (address seller, address token, uint256 price) = nftMarket
            .getTokenSellInfo(tokenId1, myNFT1);
        assertEq(seller, user1);
        assertEq(token, address(tokenA));
        assertEq(price, tokenId1Price);
    }

    function listNFT() internal {
        vm.startPrank(user1);
        myNFT1.approve(address(nftMarket), tokenId1);
        vm.expectEmit(true, true, false, true);
        emit NFTListed(
            address(myNFT1),
            tokenId1,
            user1,
            tokenId1Price,
            address(tokenB)
        );
        nftMarket.list(myNFT1, tokenId1, address(tokenB), tokenId1Price);
        (address seller, address sellToken, uint256 price) = nftMarket
            .getTokenSellInfo(tokenId1, myNFT1);
        vm.stopPrank();

        // nftmarket.onTransferReceived should list the transfered nft to the listing
        assertEq(seller, user1);
        assertEq(price, tokenId1Price);
        assertEq(address(sellToken), address(tokenB));

        // nft transfered to the nftmarket after nftContract.safeTransferFrom
        assertEq(myNFT1.ownerOf(tokenId1), address(nftMarket));
        // nft token approval cleared for the nftmarket after nftContract.safeTransferFrom
        assertEq(myNFT1.getApproved(tokenId1), address(0x0));
    }
}
