// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {VottingSystem} from "../src/VottingSystem.sol";

contract VottingSystemScript is Script {
    VottingSystem public vottingSystem;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        vottingSystem = new VottingSystem();

        vm.stopBroadcast();
    }
}
