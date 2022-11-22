// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

pragma solidity ^0.8.17;

/*
 * @dev This contract is designed to receive a token (ERC20), mint and transfer to 
        the msg.sender a ticket (ERC1155), sell a portion of the received ERC20 for 
        another ERC20 (swap) and send the swapped funds to an address.
*/

error Ticket__OnlyOneTicketPerAddress();

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
}