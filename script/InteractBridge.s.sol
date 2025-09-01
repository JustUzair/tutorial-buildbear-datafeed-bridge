// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {Bridge, IERC20, SafeERC20} from "src/Bridge.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract InteractBridge is Script {
    using SafeERC20 for IERC20;

    function run() external {
        // Load JSON from broadcast folder (network-specific)
        string memory path = string.concat(
            vm.projectRoot(), "/broadcast/DeployBridge.s.sol/", vm.toString(block.chainid), "/run-latest.json"
        );
        string memory json = vm.readFile(path);

        // Parse contract address from broadcast
        address bridgeAddr = abi.decode(vm.parseJson(json, ".transactions[0].contractAddress"), (address));
        console2.log("Bridge found at:", bridgeAddr);

        Bridge bridge = Bridge(bridgeAddr);

        // Load network config
        (, address wethToken, address usdtToken,,) = new HelperConfig().activeNetworkConfig();

        // Wallet for interaction
        address receiver = vm.envAddress("RECEIVER_WALLET");
        uint256 receiverKey = vm.envUint("RECEIVER_PRIVATE_KEY");
        console2.log("EOA Interacting with Bridge:", receiver);

        // Interact: approve WETH and call lockAndQuote
        vm.startBroadcast(receiverKey);

        uint256 amount = 1e18; // 1 WETH
        IERC20(wethToken).approve(bridgeAddr, amount);

        bridge.lockAndQuote(wethToken, usdtToken, amount, receiver);

        vm.stopBroadcast();

        console2.log("lockAndQuote called with", amount, "WETH -> expecting USDT");
    }
}
