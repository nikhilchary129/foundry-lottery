// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {raffle} from "../src/raffle.sol";
import {Helperconfig} from "../script/helperconfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../script/interaction.s.sol";

contract DeployRaffle is Script {
    function run() external returns (raffle, Helperconfig) {
        Helperconfig helperconfig = new Helperconfig();
        uint256 enteryfee;
        uint256 intervel;
        address vrfcoordinator;
        bytes32 gaslane;
        uint64 subscriptionId;
        uint32 callbackgaslimit;
        address link;
        uint256 deployerkey;

        (
            enteryfee,
            intervel,
            vrfcoordinator,
            gaslane,
            subscriptionId,
            callbackgaslimit,
            link,
            deployerkey
        ) = helperconfig.activeNetworkConfig();
        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfcoordinator,deployerkey
            );
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfcoordinator,
                subscriptionId,
                link,
                deployerkey
            );
        }
        vm.startBroadcast(deployerkey);
        raffle _raffle = new raffle(
            enteryfee,
            intervel,
            vrfcoordinator,
            gaslane,
            subscriptionId,
            callbackgaslimit
        );
        
        vm.stopBroadcast();
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addconsumer(
            address(_raffle),
            vrfcoordinator,
            subscriptionId,
            deployerkey
        );
        return (_raffle, helperconfig);
    }
}
