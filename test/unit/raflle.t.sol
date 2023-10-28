// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Helperconfig} from "../../script/helperconfig.s.sol";
import {DeployRaffle} from "../../script/deployRaffle.s.sol";
import {raffle} from "../../src/raffle.sol";
import {Vm} from "forge-std/Vm.sol";

contract Raffletest is Test {
    //events
    event enterRaffle(address indexed player);

    raffle _raffle;
    Helperconfig _helperconfig;
    uint256 enteryfee;
    uint256 intervel;
    address vrfcoordinator;

    uint64 subscriptionId;

    address link;
    uint256 devolperkey;

    address public PLAYER = makeAddr("player");
    uint256 constant STARTING_MINIMUM_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (_raffle, _helperconfig) = deployRaffle.run();

        (
            enteryfee,
            intervel,
            vrfcoordinator,
            ,
            subscriptionId,
            ,
            link,
            devolperkey
        ) = _helperconfig.activeNetworkConfig();
        vm.deal(PLAYER, 10 ether);
    }

    function testenteryfee() public view {
        uint256 fee = _raffle.getEnteranceFee();
        assert(fee == enteryfee);
    }

    ///////////////////////////////////////////////
    //////////// ->enterraffle<- //////////////////
    ///////////////////////////////////////////////
    modifier prank() {
        vm.prank(PLAYER);

        _raffle.enterraffle{value: enteryfee}();
        _;
    }

    function testraffleintialstate() public view {
        assert(_raffle.getRafflestate() == raffle.Rafflestate.open);
    }

    function testRaffleRevertsWhenNotEnoughPay() public {
        vm.prank(PLAYER);

        vm.expectRevert(raffle.ruffle__notenoughETH.selector);
        _raffle.enterraffle();
    }

    function testRaffleRecordPlayers() public prank {
        assertEq(_raffle.getRafflePlayer(0), PLAYER);

        // assert(_raffle.getRafflePlayer(_raffle.getRafflePlayerLength()-1)==PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(_raffle));
        emit enterRaffle(PLAYER);

        _raffle.enterraffle{value: enteryfee}();
    }

    modifier changetime() {
        vm.warp(block.timestamp + intervel + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testforruffleclosedentry() public prank changetime {
        _raffle.performUpkeep("");

        vm.expectRevert(raffle.ruffle__closed.selector);
        vm.prank(PLAYER);
        _raffle.enterraffle{value: enteryfee}();
    }

    ///////////////////////////////////////////////
    //////////// -> checkUpkeep <- ////////////////
    ///////////////////////////////////////////////

    // 1test. hasBalance==0; and making all true

    function testcheckUpkeepReturnsFalseOnzerobalance() public changetime {
        //making the timepassed = true

        //  _raffle.enterraffle{value: enteryfee}();
        // isopen is intially to the open as we r not interfeering with other thing
        // the process states should be open

        (bool t, ) = _raffle.checkUpkeep("");
        // console.log("kkk");
        assertEq(t, false);
    }

    function testcheckUpReturnsFalseOnRaffleClose() public prank changetime {
        _raffle.performUpkeep(""); //calculating state

        vm.prank(PLAYER);

        // _raffle.enterraffle{value: enteryfee}();
        (bool t, ) = _raffle.checkUpkeep("");
        assertEq(false, t);
    }

    ///////////////////////////////////////////////
    //////////// -> perform Upkeep <- ////////////////
    ///////////////////////////////////////////////

    function testPerformUpKeepOnlyPunsOnCheckUpKeepISTrue()
        public
        prank
        changetime
    {
        _raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertOnCheckUpkeepISfalse() public prank {
        vm.expectRevert(raffle.Raffle__UpkeepNotNeeded.selector);
        _raffle.performUpkeep("");
    }

    function testPerformUpkeepEmits() public prank changetime {
        vm.recordLogs();
        _raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        raffle.Rafflestate rstate = _raffle.getRafflestate();
        assert(requestId > 0);
        //  console.log( uint256(rstate));
        assert(raffle.Rafflestate.calculating == rstate);
    }

    ///////////////////////////////////////////////
    //////////// -> fulfillRandomWords <- ////////////////
    ///////////////////////////////////////////////
    function testfulfillRandomWordsCanOnlyBeCalledBYVRfcoordinator(
        uint256 randomRequestId
    ) public {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfcoordinator).fulfillRandomWords(
            randomRequestId,
            address(_raffle)
        );
    }

    function testfullfillrandomwordPicksaWinnerAndSendsMoney()
        public
        prank
        changetime
    {
        uint256 intialplayer = 1;
        uint256 additionalentry = 5;
        uint256 intial_balance = 2 ether;
        for (
            uint256 i = intialplayer;
            i < intialplayer + additionalentry;
            i++
        ) {
            hoax(address(uint160(i)), intial_balance);
            _raffle.enterraffle{value: enteryfee}();
        }
        uint256 intialbalanceofanyuser = intial_balance - enteryfee;

        vm.recordLogs();
        _raffle.performUpkeep("");
        uint256 contractBalanceIntially = address(_raffle).balance;

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        uint256 prevtimestamp = _raffle.getprevTimeStamp();
        VRFCoordinatorV2Mock(vrfcoordinator).fulfillRandomWords( //pretending to be the chainlink vrf
            uint256(requestId),
            address(_raffle)
        );

        assert(
            address(_raffle.getRafflePrevWinner()).balance ==
                (contractBalanceIntially + intialbalanceofanyuser)
        );

        assert(uint256(_raffle.getRafflestate()) == 0);
        assert(_raffle.getRafflePrevWinner() != address(0));
        uint256 l = _raffle.getRafflePlayerLength();
        assert(l == 0);
        assert(prevtimestamp < _raffle.getprevTimeStamp());
    }
}
