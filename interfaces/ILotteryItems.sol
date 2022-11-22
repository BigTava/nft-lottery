// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ILotteryItems is IERC1155 {
    function mintTicket(address) external;
    function mintPrize(address) external;
}