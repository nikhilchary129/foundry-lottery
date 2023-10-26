// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {Helperconfig} from "../../script/helperconfig.s.sol";
import {DeployRaffle} from "../../script/deployRaffle.s.sol";
import {raffle} from "../../src/raffle.sol";

contract Raffletest is Test {
    //events
    event enterRaffle(address indexed player);

    raffle _raffle;
    Helperconfig _helperconfig;
    uint256 enteryfee;
    uint256 intervel;
    address vrfcoordinator;
    bytes32 gaslane;
    uint64 subscriptionId;
    uint32 callbackgaslimit;
    address link;
    address public PLAYER = makeAddr("player");
    uint256 constant STARTING_MINIMUM_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (_raffle, _helperconfig) = deployRaffle.run();

        (
            enteryfee,
            intervel,
            vrfcoordinator,
            gaslane,
            subscriptionId,
            callbackgaslimit,
            link
        ) = _helperconfig.activeNetworkConfig();
        vm.deal(PLAYER, 10 ether);
    }

    ///////////////////////////////////////////////
    //////////// ->enterraffle<- //////////////////
    ///////////////////////////////////////////////

    function testraffleintialstate() public view {
        assert(_raffle.getRafflestate() == raffle.Rafflestate.open);
    }

    function testRaffleRevertsWhenNotEnoughPay() public {
        vm.prank(PLAYER);

        vm.expectRevert(raffle.ruffle__notenoughETH.selector);
        _raffle.enterraffle();
    }

    function testRaffleRecordPlayers() public {
        vm.prank(PLAYER);

        _raffle.enterraffle{value: enteryfee}();

        assertEq(_raffle.getRafflePlayer(0), PLAYER);

        // assert(_raffle.getRafflePlayer(_raffle.getRafflePlayerLength()-1)==PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(_raffle));
        emit enterRaffle(PLAYER);

        _raffle.enterraffle{value: enteryfee}();
    }

    function testforruffleclosedentry() public {
        vm.prank(PLAYER);

        _raffle.enterraffle{value: enteryfee}();

        vm.warp(block.timestamp + intervel + 1);
        vm.roll(block.number + 1);
        _raffle.performUpkeep("");

        vm.expectRevert(raffle.ruffle__closed.selector);
        vm.prank(PLAYER);
        _raffle.enterraffle{value: enteryfee}();
    }
    ///////////////////////////////////////////////
    //////////// -> checkUpkeep <- ////////////////
    ///////////////////////////////////////////////

    // 1test. hasBalance==0; and making all true
    
    function checkUpkeepReturnsFalseOn0balance() public  {
        //making the timepassed = true
      
        vm.warp(block.timestamp + intervel + 1);//incresing the block time
        vm.roll(block.number + 1);// idk

        // isopen is intially to the open as we r not interfeering with other thing
        // the process states should be open

        //as we payed the entry fee which leads us as a single player so hasPlayer true
         (bool t,)=_raffle.checkUpkeep("");
        // console.log("kkk");
       assertEq( t , true);


    }
}
