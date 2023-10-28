// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
import {raffle} from "../src/raffle.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {CreateSubscription} from "../script/interaction.s.sol";
import {LinkToken} from "../test/mocks/LInkToken.sol";


contract Helperconfig is Script {
    uint256 public constant ANVIL_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    //0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
    //0x23a0328ca573e37ed4a511cb855d53cc30f232383a0c02835e86c8f934c10af6

    struct Networkconfig {
        uint256 enteryfee;
        uint256 intervel;
        address vrfcoordinator;
        bytes32 gaslane;
        uint64 subscriptionId;
        uint32 callbackgaslimit;
        address links;
        uint256 devolperkey;
    }
    Networkconfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {activeNetworkConfig = getSepoliaconfig();}
        else {activeNetworkConfig = getAnvilconfig();}
    }

    function getSepoliaconfig() public returns (Networkconfig memory) {
        return
            Networkconfig({
                enteryfee: 0.01 ether,
                intervel: 60,
                vrfcoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,//0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
                gaslane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0, //gonna change
                callbackgaslimit: 2500000,
                links: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                devolperkey: vm.envUint("PRIVATE_KEY") 

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
                links:address(link),
                devolperkey:ANVIL_PRIVATE_KEY
                
             
            });
    }

   
}
