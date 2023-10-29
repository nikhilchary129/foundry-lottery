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
import "script/interaction.s.sol";