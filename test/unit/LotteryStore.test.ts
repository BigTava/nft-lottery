import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";

import { LotteryStore } from "../../typechain-types";
import { LotteryItems } from "../../typechain-types";
import { Token } from "../../typechain-types/contracts/Token";

const hre = require("hardhat");

describe.only("LotteryStore", function () {
  let approvedERC20: Token;
  let lotteryStore: LotteryStore;
  let lotteryItems: LotteryItems;
  let approvedERC20Owner: SignerWithAddress;
  let lotteryStoreOwner: SignerWithAddress;
  let players: SignerWithAddress[];

  before(async function () {
    const signers: SignerWithAddress[] = await ethers.getSigners();
    lotteryStoreOwner = signers[0];
    approvedERC20Owner = signers[1];
    players = signers.slice(2, 11);

    const ApprovedERC20Factory = await ethers.getContractFactory("Token");
    approvedERC20 = await ApprovedERC20Factory.connect(
      approvedERC20Owner
    ).deploy();

    const LotteryStoreFactory = await ethers.getContractFactory("LotteryStore");
    lotteryStore = await LotteryStoreFactory.connect(lotteryStoreOwner).deploy(
      approvedERC20.address
    );

    const LotteryItemsFactory = await ethers.getContractFactory("LotteryItems");
  });

  describe("constructor", function () {
    it("Approved ERC20 should be set", async function () {
      expect(await lotteryStore.i_approvedERC20()).to.equal(
        approvedERC20.address
      );
    });
  });

  describe("Create lottery", function () {
    it("Owner should be able to open new lottery", async function () {
      await expect(lotteryStore.connect(lotteryStoreOwner).openNewLottery()).to
        .be.not.reverted;
    });

    it("Players should not be able to create new lottery", async function () {
      const player: SignerWithAddress = players[0];
      await expect(
        lotteryStore.connect(player).openNewLottery()
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Current lottery index should be set to 1", async function () {
      expect(
        await lotteryStore.connect(lotteryStoreOwner).s_currentLottery()
      ).to.be.equal(1);
    });

    it("Lottery data should be set correctly", async function () {
      const lotteryData = await lotteryStore
        .connect(lotteryStoreOwner)
        .s_lottery(1);
      expect(lotteryData.lotteryId).to.be.equal(1);
      expect(lotteryData.lotteryWinner).to.be.equal(0);
      expect(lotteryData.totalTickets).to.be.equal(0);
      expect(lotteryData.ticketPrice).to.be.equal(100);
      expect(lotteryData.state).to.be.equal(0);
    });
  });

  describe("Buy lottery ticket", function () {
    let player_1: SignerWithAddress;
    let player_2: SignerWithAddress;

    before(async function () {
      await lotteryStore.connect(lotteryStoreOwner).openNewLottery();
      player_1 = players[0];
      player_2 = players[1];

      const itemsAddress = await lotteryStore
        .connect(player_1)
        .s_lotteryItems(2);
      const ItemsContractFactory = await ethers.getContractFactory(
        "LotteryItems"
      );
      lotteryItems = await ItemsContractFactory.attach(itemsAddress);

      await approvedERC20
        .connect(approvedERC20Owner)
        .transfer(player_1.address, 1000);

      await approvedERC20
        .connect(approvedERC20Owner)
        .transfer(player_2.address, 10);
    });

    it("Player should be able to buy new ticket", async function () {
      await approvedERC20
        .connect(player_1)
        .increaseAllowance(lotteryStore.address, 100);

      expect(await lotteryStore.connect(player_1).buyTicket()).to.be.not
        .reverted;
    });

    it("Player owns a ticket", async function () {
      expect(await lotteryItems.balanceOf(player_1.address, 0)).to.be.equal(1);
    });

    it("Player should not be able to buy new ticket twice", async function () {
      await approvedERC20
        .connect(player_1)
        .increaseAllowance(lotteryStore.address, 100);

      await expect(lotteryStore.connect(player_1).buyTicket()).to.be.reverted;
    });

    it("Player should not be able to buy new ticket if it does not have enough balance", async function () {
      await approvedERC20
        .connect(player_2)
        .increaseAllowance(lotteryStore.address, 100);

      await expect(
        lotteryStore.connect(player_2).buyTicket()
      ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
    });
  });
});

// testnet tokens goerli and chainlink
// Complete randomness contract
// test randomness integration test
// frontend
