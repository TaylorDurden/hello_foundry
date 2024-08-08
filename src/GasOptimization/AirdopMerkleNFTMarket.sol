// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "forge-std/console.sol";

contract AirdopMerkleNFTMarket {
  using Address for address;

  IERC20 public token;
  bytes32 public merkleRoot;
  mapping(address => bool) public claimed;

  event NFTClaimed(address indexed user, uint256 tokenId);

  constructor(address _token, bytes32 _merkleRoot) {
    token = IERC20(_token);
    merkleRoot = _merkleRoot;
  }

  function permitPrePay(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    IERC20Permit(address(token)).permit(owner, spender, value, deadline, v, r, s);
  }

  function claimNFT(address to, uint256 amount, bytes32[] calldata merkleProof, address nft, uint256 tokenId) public {
    require(!claimed[to], "Already claimed");
    bytes32 leaf = keccak256(abi.encodePacked(to, amount));
    require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid proof");

    claimed[to] = true;
    require(token.transferFrom(to, address(this), amount), "Token transfer failed");

    // Mint or transfer NFT to `to` (implement NFT transfer logic here)
    // Assuming a simple mint function for demonstration purposes
    (bool success, ) = nft.call(abi.encodeWithSignature("mint(address,uint256)", to, tokenId));
    require(success, "NFT mint failed");

    emit NFTClaimed(to, tokenId);
  }

  function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      (bool success, bytes memory returndata) = address(this).delegatecall(data[i]);
      require(success);
      results[i] = returndata;
    }
  }
}
