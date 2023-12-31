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
        vm.startBroadcast(deployerkey);

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
            uint256 deployerkey
        ) = helperconfig.activeNetworkConfig();
        fundSubscription(vrfcoordinator, subid, link, deployerkey);
    }

    function fundSubscription(
        address vrfcoordinator,
        uint64 subid,
        address link,
        uint256 deployerkey
    ) public {
        if (block.chainid == 31337) {
            vm.startBroadcast(deployerkey);
            VRFCoordinatorV2Mock(vrfcoordinator).fundSubscription(
                subid,
                FUND_AMOUNT
            );

            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerkey);
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
      
        VRFCoordinatorV2Mock(vrfcoordinator).addConsumer(
            subid,
            contractToAddToVrf
        );

        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
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

        addconsumer(mostRecentlyDeployed, vrfcoordinator, subid, deployerkey);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
