// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {EtherWallet} from "../src/EtherWallet.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployEtherWallet is Script {
    function run() external returns (EtherWallet) {
        HelperConfig helperConfig = new HelperConfig();
        address ethPriceFeed = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        EtherWallet deployEtherWallet = new EtherWallet(ethPriceFeed);
        vm.stopBroadcast();
        return deployEtherWallet;
    }
}
