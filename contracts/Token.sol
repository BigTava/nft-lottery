//SPDX-License-Identifier: MIT
/*
 * @dev Lottery's approved ERC20
*/
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    constructor() ERC20("WBNBToken", "WBNB") {
        _mint(msg.sender, 1000000E18);
    }
}