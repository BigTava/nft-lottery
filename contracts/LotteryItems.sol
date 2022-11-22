// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

error Ticket__OnlyOneTicketPerAddress();
error Prize__PlayerAlreadyHasPrize();

contract LotteryItems is ERC1155, Ownable {

    //----------------- STORAGE -----------------
    uint256 public constant TICKET = 0;
    uint256 public constant PRIZE = 1;

    //----------------- FUNCTIONS ---------------
    constructor() ERC1155("") {
    }

    function mintTicket(address _player) public onlyOwner {
        if (balanceOf(_player, TICKET) > 0) {
            revert Ticket__OnlyOneTicketPerAddress();
        }
        _mint(_player, TICKET, 1,"0x000");
    }

    function mintPrize(address _player) public onlyOwner {
        if (balanceOf(_player, PRIZE) > 0) {
            revert Prize__PlayerAlreadyHasPrize();
        }
        _mint(_player, PRIZE, 1,"0x000");
    }
}