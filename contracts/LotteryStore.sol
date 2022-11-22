// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "./StoreData.sol";
import "hardhat/console.sol";

contract LotteryStore is StoreData, VRFConsumerBaseV2 {
    /**
     * @dev This contract is designed to receive a token (ERC20), 
            mint and transfer to the msg.sender a ticket (ERC1155), 
            sell a portion of the received ERC20 for another ERC20 (swap) 
            and send the swapped funds to an address.
    */

    //----------------- STORAGE -----------------
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint64 immutable s_subscriptionId;
    bytes32 immutable s_keyHash;
    uint32 constant CALLBACK_GAS_LIMIT = 100000;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant NUM_WORDS = 1; // number of values generated

    address public s_recentWinner;
    uint public s_requestId;

    //----------------- EVENTS ------------------
    event WinnerPicked(
        uint256 lotteryId,
        address indexed winner
    );

    event RequestedLotteryWinner(uint indexed requestId);

    //----------------- FUNCTIONS ---------------
    constructor(
        address _approvedERC20,
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) StoreData(_approvedERC20) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
    }

    function buyTicket() public {
        mintTicket();

        if (s_lottery[s_currentLottery].totalTickets == 10) {
            s_requestId = _pickRandomWinner();
        }
    }

    /**
     * @notice Requests randomness
     */
    function _pickRandomWinner() internal returns (uint _requestId) {
        // Will revert if subscription is not set and funded.
        _requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
        emit RequestedLotteryWinner(s_requestId);
    }

    /**
     * @notice Callback function used by VRF Coordinator
     *
     * @param randomWords - array of random results from VRF Coordinator
     */
    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords)
        internal
        override
    {   
        uint indexOfWinner = randomWords[0] % 10;
        address recentWinner = s_lotteryPlayers[s_currentLottery][indexOfWinner].player;
        s_recentWinner = recentWinner;
        

        mintPrize(recentWinner);

        s_lottery[s_currentLottery].state = LotteryState.COMMITTED;
        emit WinnerPicked(s_currentLottery, recentWinner);
    }
}