// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
import {raffle} from "../src/raffle.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {CreateSubscription} from "../script/interaction.s.sol";
import {LinkToken} from "../test/mocks/LInkToken.sol";


contract Helperconfig is Script {
    struct Networkconfig {
        uint256 enteryfee;
        uint256 intervel;
        address vrfcoordinator;
        bytes32 gaslane;
        uint64 subscriptionId;
        uint32 callbackgaslimit;
        address links;
    }
    Networkconfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) activeNetworkConfig = getSepoliaconfig();
        else activeNetworkConfig = getAnvilconfig();
    }

    function getSepoliaconfig() pure public returns (Networkconfig memory) {
        return
            Networkconfig({
                enteryfee: 0.01 ether,
                intervel: 60,
                vrfcoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                gaslane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0, //gonna change
                callbackgaslimit: 2500000,
                links: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }

    function getAnvilconfig() public returns (Networkconfig memory) {
        if (activeNetworkConfig.vrfcoordinator != address(0))
            return activeNetworkConfig;

        uint96 basefee = 0.01 ether;
        uint96 gasPriceLink = 1e9;

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfcoordinator = new VRFCoordinatorV2Mock(
            basefee,
            gasPriceLink
        );
        LinkToken link=new LinkToken();
        vm.stopBroadcast();

        return
            Networkconfig({
                enteryfee: 0.01 ether,
                intervel: 60,
                vrfcoordinator: address(vrfcoordinator),
                gaslane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId:  0, //gonna change
                callbackgaslimit: 2500000,
                links:address(link)
             
            });
    }

    function getEtherconfig() pure public returns (Networkconfig memory) {
        return
            Networkconfig({
                enteryfee: 0.01 ether,
                intervel: 60,
                vrfcoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                gaslane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0, //gonna change
                callbackgaslimit: 2500000,
                links:0x514910771AF9Ca656af840dff83E8264EcF986CA
            });
    }
}
