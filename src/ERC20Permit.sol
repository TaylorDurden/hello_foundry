// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";

contract ERC20Permit is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
