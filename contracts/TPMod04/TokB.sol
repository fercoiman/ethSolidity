// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenB is ERC20("TokenB", "TOKB") {
    constructor()
        
    {
        _mint(msg.sender, 100000 * 10 ** decimals());
    }

}
