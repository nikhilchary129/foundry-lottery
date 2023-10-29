// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {Helperconfig} from "../script/helperconfig.s.sol";

import {Test, console} from "forge-std/Test.sol";

/**
 *
 * @title
 * @author
 * @notice this contract iffor creating sample raffle
 */

contract raffle is VRFConsumerBaseV2 {
    error ruffle__notenoughETH();
    error Raffle__transferFailed();
    error ruffle__closed();
    error Raffle__UpkeepNotNeeded();

    enum Rafflestate {
        open,
        calculating
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_enteryfee;
    uint private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfcoordinator;
    bytes32 private immutable i_gaslane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackgaslimit;

    address payable[] private s_players; //payabale so that we can send the winner prize
    uint256 private s_prevtimestamp;
    address private s_recentWinner;
    Rafflestate private s_state;

    //events // we use event to emit the data so that it will be easy to retrive in front end

    event enterRaffle(address indexed player);
    event winnerpicker(address indexed s_recentWinner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 enteryfee,
        uint256 intervel,
        address vrfcoordinator,
        bytes32 gaslane,
        uint64 subscriptionId,
        uint32 callbackgaslimit
    ) VRFConsumerBaseV2(vrfcoordinator) {
        i_enteryfee = enteryfee;
        i_interval = intervel;
        i_vrfcoordinator = VRFCoordinatorV2Interface(vrfcoordinator);
        i_subscriptionId = subscriptionId;
        i_gaslane = gaslane;
        i_callbackgaslimit = callbackgaslimit;
        s_prevtimestamp = block.timestamp;
        s_state = Rafflestate.open;
    }

    function enterraffle() public payable {
        if (s_state == Rafflestate.calculating) revert ruffle__closed();
        if (msg.value < i_enteryfee) revert ruffle__notenoughETH();
        s_players.push(payable(msg.sender)); //payable allow to pay in future

        emit enterRaffle(msg.sender);
    }

    function fulfillRandomWords(
        uint256, //requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexofwinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexofwinner];
        s_recentWinner = winner;
        s_players = new address payable[](0);
        s_prevtimestamp = block.timestamp;
        s_state = Rafflestate.open;

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) revert Raffle__transferFailed();

        emit winnerpicker(s_recentWinner);
    }

    function checkUpkeep(
        bytes memory /* perfirmdata */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timepassed = (block.timestamp - s_prevtimestamp >= i_interval);

        bool isOpen = Rafflestate.open == s_state;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayer = s_players.length > 0;
        console.log(timepassed, "timepassed");
        console.log(isOpen, "isOpen");
        console.log(hasBalance, "hasBalance");
        console.log(hasPlayer, "hasPlayer");
        upkeepNeeded = (timepassed && isOpen && hasBalance && hasPlayer);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* perfirmdata */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) revert Raffle__UpkeepNotNeeded();
        s_state = Rafflestate.calculating;

        uint256 reqestedid = i_vrfcoordinator.requestRandomWords(
            i_gaslane, //gas line
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackgaslimit,
            NUM_WORDS
        );
          console.log(reqestedid,"resquest id");
        emit RequestedRaffleWinner(reqestedid);
    }

    //getterfunction

    function getEnteranceFee() external view returns (uint256) {
        return i_enteryfee;
    }

    function getRafflestate() external view returns (Rafflestate) {
        return s_state;
    }

    function getRafflePlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getRafflePlayerLength() external view returns (uint256) {
        return s_players.length;
    }

    function getprevTimeStamp() external view returns (uint256) {
        return s_prevtimestamp;
    }

    function getRafflePrevWinner() external view returns (address) {
        return s_recentWinner;
    }
}
