// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import "../../src/GasOptimization/AirdopMerkleNFTMarket.sol";
import {Merkle} from "../MerkleTree/MerkelTree.sol";

contract Token is ERC20, ERC20Permit {
  constructor() ERC20("Token", "TKN") ERC20Permit("Token") {
    _mint(msg.sender, 1000000 * 10 ** decimals());
  }
}

contract MyNFT is ERC721, Ownable {
  uint256 private _tokenIdCounter;

  constructor(address owner) ERC721("NFT", "NFT") Ownable(owner) {}

  function mint(address to, uint256 tokenId) public onlyOwner {
    _mint(to, tokenId);
  }
}

contract AirdopMerkleNFTMarketTest is Test {
  struct WhiteList {
    address user;
    uint256 amount;
  }
  Token private token;
  MyNFT private nft;
  AirdopMerkleNFTMarket private market;
  address private owner;
  address private user;
  uint256 private userPK;
  uint256 private price;
  bytes32[] proof;

  function setUp() public {
    owner = vm.addr(1);
    (user, userPK) = makeAddrAndKey("user");
    vm.startPrank(owner);
    token = new Token();
    price = 50 * 10 ** token.decimals();
    Merkle merkleTree = new Merkle();
    bytes32[] memory wl = new bytes32[](2);
    wl[0] = keccak256(abi.encodePacked(user, price));
    wl[1] = keccak256(abi.encodePacked(owner, price));
    bytes32 merkleRoot = merkleTree.getRoot(wl);
    proof = merkleTree.getProof(wl, 0);
    console.log("proof.length", proof.length);
    market = new AirdopMerkleNFTMarket(address(token), merkleRoot);
    nft = new MyNFT(address(market));
    token.transfer(user, 1000 * 10 ** token.decimals());
    vm.stopPrank();
  }

  function testPermitPrePayAndClaimNFT() public {
    vm.startPrank(user);
    uint256 tokenId = 1;
    uint256 deadline = block.timestamp + 1 hours;

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        token.DOMAIN_SEPARATOR(),
        keccak256(
          abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
            user,
            address(market),
            price,
            token.nonces(user),
            deadline
          )
        )
      )
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPK, digest);

    bytes[] memory calls = new bytes[](2);
    calls[0] = abi.encodeWithSignature(
      "permitPrePay(address,address,uint256,uint256,uint8,bytes32,bytes32)",
      user,
      address(market),
      price,
      deadline,
      v,
      r,
      s
    );

    calls[1] = abi.encodeWithSignature(
      "claimNFT(address,uint256,bytes32[],address,uint256)",
      user,
      price,
      proof,
      address(nft),
      tokenId
    );

    market.multicall(calls);

    assertTrue(market.claimed(user));
    assertTrue(token.balanceOf(address(market)) == price);
    assertEq(nft.ownerOf(tokenId), user);
    vm.stopPrank();
  }
}
