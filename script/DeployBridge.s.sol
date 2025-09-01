// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {HelperConfig} from "script/HelperConfig.s.sol";
import {Bridge, IERC20, SafeERC20} from "src/Bridge.sol";

contract DeployBridge is Script {
    using SafeERC20 for IERC20;

    function run() external {
        (uint256 deployerKey, address wethToken, address usdtToken, address wethUsdFeed, address deployer) =
            new HelperConfig().activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Deploy bridge
        Bridge bridge = new Bridge(wethToken, usdtToken, wethUsdFeed);

        // Optionally pre-fund bridge with WETH + USDT liquidity from deployer
        uint256 wethBal = IERC20(wethToken).balanceOf(deployer);
        uint256 usdtBal = IERC20(usdtToken).balanceOf(deployer);
        require(wethBal > 1000e18, "Fund your account with atleast 1000 WETH tokens");
        require(usdtBal > 25000e6, "Fund your account with atleast 25000 USDT tokens");

        if (wethBal > 0) {
            // IERC20(wethToken).approve(address(bridge), 1000e18);
            IERC20(wethToken).safeTransfer(address(bridge), 1000e18);
        }
        if (usdtBal > 0) {
            // IERC20(usdtToken).approve(address(bridge), 25000e6);
            IERC20(usdtToken).safeTransfer(address(bridge), 25000e6);
        }

        vm.stopBroadcast();

        console2.log("Bridge deployed at:", address(bridge));
        console2.log("WETH/USD feed:", wethUsdFeed);
    }
}
