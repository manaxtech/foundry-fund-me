// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

abstract contract CodeConstants {
    uint8 constant DECIMALS = 8;
    int256 constant INITIAL_PRICE = 2000e8;

    uint256 constant ETH_MAINNET_CHAINID = 1;
    uint256 constant ETH_SEPOLIA_CHAINID = 11155111;
    uint256 constant LOCAL_CHAINID = 31337;
    uint256 constant ZKSYNC_CHAINID = 324;
    uint256 constant ZKSYNC_SEPOLIA_CHAINID = 300;
}

contract HelperConfig is CodeConstants, Script {
    struct NetworkConfig {
        address priceFeed;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == ETH_MAINNET_CHAINID) {
            activeNetworkConfig = getMainnetEthConfig();
        } else if (block.chainid == ETH_SEPOLIA_CHAINID) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == ZKSYNC_CHAINID) {
            activeNetworkConfig = getZkSyncEraConfig();
        } else if (block.chainid == ZKSYNC_SEPOLIA_CHAINID) {
            activeNetworkConfig = getZkSyncSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getMainnetEthConfig() private pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            });
    }

    function getSepoliaEthConfig() private pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
            });
    }

    function getZkSyncEraConfig() private pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                priceFeed: 0x6D41d1dc818112880b40e26BD6FD347E41008eDA
            });
    }

    function getZkSyncSepoliaConfig()
        private
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                priceFeed: 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF
            });
    }

    function getOrCreateAnvilConfig() private returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();
        return NetworkConfig({priceFeed: address(mockPriceFeed)});
    }
}
