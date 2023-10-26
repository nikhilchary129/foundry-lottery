// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script,console} from "forge-std/Script.sol";
import {raffle} from "../src/raffle.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Helperconfig} from "../script/helperconfig.s.sol";
import {LinkToken} from "../test/mocks/LInkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

uint96  constant FUND_AMOUNT=3 ether;

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        Helperconfig helperconfig = new Helperconfig();
        (, , address vrfcoordinator, , , ,) = helperconfig.activeNetworkConfig();
        return createSubscription(vrfcoordinator);
    }
    function createSubscription(address vrfcoordinator) public  returns(uint64) {
        vm.startBroadcast();

        uint64 subid= VRFCoordinatorV2Mock(vrfcoordinator).createSubscription();
        console.log("your subid: ",subid);
        vm.stopBroadcast();
        return subid;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    function fundSubscriptionUsingConfig ()public {
         Helperconfig helperconfig = new Helperconfig();
        (, , address vrfcoordinator, ,uint64 subid , ,address link) = helperconfig.activeNetworkConfig();
        fundSubscription(vrfcoordinator,subid,link);
    }
    function fundSubscription(address vrfcoordinator,uint64 subid,address link)public {
            if(block.chainid==31337){
                vm.startBroadcast();
                VRFCoordinatorV2Mock(vrfcoordinator).fundSubscription(
                    subid,
                    FUND_AMOUNT
                );

                vm.stopBroadcast();
            }else {
                vm.startBroadcast();
                LinkToken(link).transferAndCall(
                    vrfcoordinator,
                    FUND_AMOUNT,
                    abi.encode(subid)
                );
                vm.stopBroadcast();

            }
    }
    function run()external{
        fundSubscriptionUsingConfig();
    }
}
contract AddConsumer is Script {
    function addconsumer(address _raffle, address vrfcoordinator,uint64 subid)public {

            vm.startBroadcast();

            VRFCoordinatorV2Mock(vrfcoordinator).addConsumer(subid,_raffle);

            vm.stopBroadcast();
    }

    function addConsumerUsingConfig( address _raffle) public {
              Helperconfig helperconfig = new Helperconfig();
        (, , address vrfcoordinator, ,uint64 subid , ,) = helperconfig.activeNetworkConfig();
        addconsumer(_raffle,vrfcoordinator,subid);
    }

    function run() external{
             address _raffle = DevOpsTools.get_most_recent_deployment("raffle", block.chainid);
             addConsumerUsingConfig(_raffle);
    }
}
