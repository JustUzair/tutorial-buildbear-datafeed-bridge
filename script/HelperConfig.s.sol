// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 deployerKey;
        address wethToken;
        address usdtToken;
        address wethUsdFeed;
        address deployer;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getEthMainnetConfig();
        } else if (block.chainid == 137) {
            activeNetworkConfig = getPolygonMainnetConfig();
        } else {
            revert("Unsupported network");
        }
    }

    function getEthMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            deployerKey: vm.envUint("PRIVATE_KEY"),
            wethToken: vm.envAddress("ETH_WETH_TOKEN"), // BuildBear faucet weth token
            usdtToken: vm.envAddress("ETH_USDT_TOKEN"), // BuildBear faucet USDT token
            wethUsdFeed: vm.envAddress("MAINNET_FEED_WETH_USD"),
            deployer: vm.envAddress("WALLET_ADDRESS")
        });
    }

    function getPolygonMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            deployerKey: vm.envUint("PRIVATE_KEY"),
            wethToken: vm.envAddress("POL_WETH_TOKEN"), // BuildBear faucet weth token
            usdtToken: vm.envAddress("POL_USDT_TOKEN"), // BuildBear faucet USDT token
            wethUsdFeed: vm.envAddress("POLYGON_FEED_WETH_USD"),
            deployer: vm.envAddress("WALLET_ADDRESS")
        });
    }
}
