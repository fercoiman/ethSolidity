// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenA is ERC20("TokenA", "TOKA") {
    constructor()
        
    {
        _mint(msg.sender, 70000 * 10 ** decimals());
    }

}
