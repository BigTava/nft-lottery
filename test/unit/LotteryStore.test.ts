import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { network } = require("hardhat");
import { expect } from "chai";
import { ethers } from "hardhat";
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

const {
  networkConfig,
  developmentChains,
} = require("../../helper-hardhat-config");
import { LotteryStore } from "../../typechain-types";
import { LotteryItems } from "../../typechain-types";
import { Token } from "../../typechain-types/contracts/Token";

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("Lottery store", async function () {
      async function deployLotteryStore() {
        let approvedERC20: Token;
        let lotteryStore: LotteryStore;
        let approvedERC20Owner: SignerWithAddress;
        let lotteryStoreOwner: SignerWithAddress;
        let players: SignerWithAddress[];

        const signers: SignerWithAddress[] = await ethers.getSigners();
        lotteryStoreOwner = signers[0];
        approvedERC20Owner = signers[1];
        players = signers.slice(2, 12);

        // DEPLOY ERC20
        const ApprovedERC20Factory = await ethers.getContractFactory("Token");
        approvedERC20 = await ApprovedERC20Factory.connect(
          approvedERC20Owner
        ).deploy();

        // DEPLOY LotteryStore Contract
        const BASE_FEE = "100000000000000000";
        const GAS_PRICE_LINK = "1000000000"; // 0.000000001 LINK per gas

        const chainId = network.config.chainId;

        const VRFCoordinatorV2MockFactory = await ethers.getContractFactory(
          "VRFCoordinatorV2Mock"
        );
        const VRFCoordinatorV2Mock = await VRFCoordinatorV2MockFactory.deploy(
          BASE_FEE,
          GAS_PRICE_LINK
        );

        const fundAmount =
          networkConfig[chainId]["fundAmount"] || "1000000000000000000";
        const transaction = await VRFCoordinatorV2Mock.createSubscription();
        const transactionReceipt = await transaction.wait(1);
        const subscriptionId = ethers.BigNumber.from(
          transactionReceipt.events![0].topics[1]
        );
        await VRFCoordinatorV2Mock.fundSubscription(subscriptionId, fundAmount);

        const vrfCoordinatorAddress = VRFCoordinatorV2Mock.address;
        const keyHash =
          networkConfig[chainId]["keyHash"] ||
          "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc";

        const LotteryStoreFactory = await ethers.getContractFactory(
          "LotteryStore"
        );
        lotteryStore = await LotteryStoreFactory.connect(
          lotteryStoreOwner
        ).deploy(
          approvedERC20.address,
          subscriptionId,
          vrfCoordinatorAddress,
          keyHash
        );

        await VRFCoordinatorV2Mock.addConsumer(
          subscriptionId,
          lotteryStore.address
        );

        return {
          lotteryStore,
          VRFCoordinatorV2Mock,
          approvedERC20,
          approvedERC20Owner,
          lotteryStoreOwner,
          players,
        };
      }

      describe("Get lottery winner", function () {
        let _approvedERC20: Token;
        let _lotteryStore: LotteryStore;
        let _approvedERC20Owner: SignerWithAddress;
        let _lotteryStoreOwner: SignerWithAddress;
        let _players: SignerWithAddress[];
        let _VRFCoordinatorV2Mock: any;

        before(async function () {
          const {
            lotteryStore,
            approvedERC20,
            VRFCoordinatorV2Mock,
            approvedERC20Owner,
            lotteryStoreOwner,
            players,
          } = await loadFixture(deployLotteryStore);
          _approvedERC20 = approvedERC20;
          _lotteryStore = lotteryStore;
          _VRFCoordinatorV2Mock = VRFCoordinatorV2Mock;
          _approvedERC20Owner = approvedERC20Owner;
          _lotteryStore = lotteryStore;
          _lotteryStoreOwner = lotteryStoreOwner;
          _players = players;

          await lotteryStore.connect(lotteryStoreOwner).openNewLottery();
        });

        it("Should successfully request a random winner", async function () {
          _players.forEach(async (player: SignerWithAddress, index: number) => {
            await _approvedERC20
              .connect(_approvedERC20Owner)
              .transfer(player.address, 1000);

            await _approvedERC20
              .connect(player)
              .increaseAllowance(_lotteryStore.address, 100);

            if (index == 9) {
              await expect(_lotteryStore.connect(player).buyTicket()).to.emit(
                _lotteryStore,
                "RequestedLotteryWinner"
              );
              return "";
            }
            _lotteryStore.connect(player).buyTicket();
          });
        });

        it("Should successfully pick a winner", async function () {
          const requestId = await _lotteryStore
            .connect(_lotteryStoreOwner)
            .s_requestId();

          // simulate callback from the oracle network
          await expect(
            _VRFCoordinatorV2Mock.fulfillRandomWords(
              requestId,
              _lotteryStore.address
            )
          ).to.emit(_lotteryStore, "WinnerPicked");
        });

        it("Winner should be able to mint the prize NFT", async function () {
          const recentWinner = await _lotteryStore
            .connect(_lotteryStoreOwner)
            .s_recentWinner();

          const itemsAddress = await _lotteryStore
            .connect(_lotteryStoreOwner)
            .s_lotteryItems(1);
          const ItemsContractFactory = await ethers.getContractFactory(
            "LotteryItems"
          );
          const lotteryItems: LotteryItems = await ItemsContractFactory.attach(
            itemsAddress
          );

          expect(await lotteryItems.balanceOf(recentWinner, 1)).to.be.equal(1);
        });
      });
    });
