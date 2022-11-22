// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../interfaces/ILotteryItems.sol";
import "./LotteryItems.sol";
import "hardhat/console.sol";

/*
 * @dev This contract is designed to receive a token (ERC20), mint and transfer to 
        the msg.sender a ticket (ERC1155), sell a portion of the received ERC20 for 
        another ERC20 (swap) and send the swapped funds to an address.
*/

/* Errors */
error Lottery__SendMoreToEnterLottery();
error Lottery__LotteryNotOpen();
error Lottery__ErrorOpeningNextLottery();

contract LotteryStore is Ownable, ERC1155Holder {
    /**
     * @dev This contract is designed to receive a token (ERC20), 
            mint and transfer to the msg.sender a ticket (ERC1155), 
            sell a portion of the received ERC20 for another ERC20 (swap) 
            and send the swapped funds to an address.
    */

    //----------------- TYPES -----------------
    enum LotteryState {
        OPEN, COMMITTED
    }

    struct LotteryData {
        uint lotteryId; // Lottery Id
        uint lotteryWinner;
        uint totalTickets;
        uint256 ticketPrice;
        LotteryState state;
    }


    struct TicketsData {
        address player;
        uint id;
    }

    //----------------- STORAGE -----------------
    address public immutable i_approvedERC20;

    // Current lottery id to buy tickets.
    uint public s_currentLottery;

    // Mapping lottery id => details of the lottery.
    mapping (uint => LotteryData) public s_lottery;

    // Mapping of lottery id => user tickets details of each lottery in sequence.
    mapping (uint => TicketsData[]) public s_lotteryPlayers;

    // Mapping of lottery id => items contract of each lottery.
    mapping (uint => LotteryItems) public s_lotteryItems;

    //----------------- EVENTS ------------------
    event TicketSale(
        address indexed player
    );

    event LotteryWinner(
        uint256 lotteryId,
        address indexed winner
    );

    //----------------- MODIFIERS ---------------

    //----------------- FUNCTIONS ---------------
    
    constructor(address _i_approvedERC20) {
        i_approvedERC20 = _i_approvedERC20;
    }

    function buyTicket() public {
        LotteryData storage _currentLottery = s_lottery[s_currentLottery];

        if (_currentLottery.state != LotteryState.OPEN) {
            revert Lottery__LotteryNotOpen();
        }

        // check allowance
        if (IERC20(i_approvedERC20).allowance(msg.sender, address(this)) < _currentLottery.ticketPrice) {
            revert Lottery__SendMoreToEnterLottery();
        }

        // pay ticket
        IERC20(i_approvedERC20).transferFrom(msg.sender, address(this),  _currentLottery.ticketPrice);

        // mint ticket
        LotteryItems _lotteryItems = s_lotteryItems[_currentLottery.lotteryId];
        _lotteryItems.mintTicket(msg.sender);

        _addTicket(msg.sender);
        emit TicketSale(msg.sender);

        if (_currentLottery.totalTickets == 10) {
            _currentLottery.state = LotteryState.COMMITTED;
        }
    }

    /**
     * @dev Add ticket to current lottery.
     * @param _player player address.
    */
    function _addTicket(address _player) internal {
        s_lottery[s_currentLottery].totalTickets += 1;
        s_lotteryPlayers[s_currentLottery].push(
            TicketsData(
                _player, 
                s_lottery[s_currentLottery].totalTickets
            )
        );
    }

    /**
     * @dev Create new lottery and commit the current ongoing lottery.
    */
    function openNewLottery() external onlyOwner {
        uint _currentLottery = s_currentLottery;

        if (_currentLottery != 0) {
            // Commit current lottery.
            _commitCurrentLottery(_currentLottery);
        }

        // Open new lottery
        uint _nextLottery = _currentLottery + 1;
        s_lottery[_nextLottery] = LotteryData({
                lotteryId: _nextLottery,
                lotteryWinner: 0,
                totalTickets: 0,
                ticketPrice: 100,
                state: LotteryState.OPEN
                }
            );

        // Create new lottery items
        s_lotteryItems[_nextLottery] = new LotteryItems();

        
        if (s_lotteryPlayers[_nextLottery].length > 0) {
            revert Lottery__ErrorOpeningNextLottery();
        }

        s_currentLottery++;
    }

    /**
     * @dev Commit current lottery
     * @param _commitLotteryId commit lottery id.
    */
    function _commitCurrentLottery(uint _commitLotteryId) internal {
        LotteryData storage commitLottery = s_lottery[_commitLotteryId];
        require(commitLottery.state == LotteryState.OPEN, "lottery already committed");

        // Deposit assets in vault.
        commitLottery.state = LotteryState.COMMITTED;
    }

}