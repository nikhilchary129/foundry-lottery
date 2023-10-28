// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script, console} from "forge-std/Script.sol";
import {raffle} from "../src/raffle.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Helperconfig} from "../script/helperconfig.s.sol";
import {LinkToken} from "../test/mocks/LInkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

uint96 constant FUND_AMOUNT = 3 ether;

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        Helperconfig helperconfig = new Helperconfig();
        (, , address vrfcoordinator, , , , , uint256 deployerkey) = helperconfig
            .activeNetworkConfig();
        return createSubscription(vrfcoordinator, deployerkey);
    }

    function createSubscription(
        address vrfcoordinator,
        uint256 deployerkey
    ) public returns (uint64) {
        vm.startBroadcast();

        uint64 subid = VRFCoordinatorV2Mock(vrfcoordinator)
            .createSubscription();
        console.log("your subid: ", subid);
        vm.stopBroadcast();
        return subid;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    function fundSubscriptionUsingConfig() public {
        Helperconfig helperconfig = new Helperconfig();
        (
            ,
            ,
            address vrfcoordinator,
            ,
            uint64 subid,
            ,
            address link,

        ) = helperconfig.activeNetworkConfig();
        fundSubscription(vrfcoordinator, subid, link);
    }

    function fundSubscription(
        address vrfcoordinator,
        uint64 subid,
        address link
    ) public {
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfcoordinator).fundSubscription(
                subid,
                FUND_AMOUNT
            );

            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfcoordinator,
                FUND_AMOUNT,
                abi.encode(subid)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addconsumer(
        address contractToAddToVrf,
        address vrfcoordinator,
        uint64 subid,
        uint256 deployerkey
    ) public {
        vm.startBroadcast(deployerkey);
        console.log(msg.sender);
        VRFCoordinatorV2Mock(vrfcoordinator).addConsumer(subid, contractToAddToVrf);
        
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address contractToAddToVrf) public {
        Helperconfig helperconfig = new Helperconfig();
        (
            ,
            ,
            address vrfcoordinator,
            ,
            uint64 subid,
            ,
            ,
            uint256 deployerkey
        ) = helperconfig.activeNetworkConfig();
        
        addconsumer(contractToAddToVrf, vrfcoordinator, subid, deployerkey);
    }

    function run() external {
        address contractToAddToVrf = DevOpsTools.get_most_recent_deployment(
            "raffle",
            block.chainid
        );
        addConsumerUsingConfig(contractToAddToVrf);
    }
}
