// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC20, ERC20Burnable} from "@oz/token/ERC20/extensions/ERC20Burnable.sol";
import {Context} from "@oz/utils/Context.sol";

contract ERC20Mintable is Context, ERC20Burnable {
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 initialDecimals) ERC20(name, symbol) {
        _decimals = initialDecimals;
    }

    // Free to mint
    function mint(address to, uint256 value) external {
        _mint(to, value);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
