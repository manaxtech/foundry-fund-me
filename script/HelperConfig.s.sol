// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "test/mocks/MockAggregatorV3.sol";

abstract contract CodeConstants {
    uint8 constant DECIMALS = 8;
    int256 constant INITIAL_ANSWER = 2000e8;

    uint256 constant SEPOLIA_CHAINID = 11155111;
    uint256 constant MAINNET_CHAINID = 1;
    uint256 constant LOCAL_CHAINID = 31337;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__ChainIdNotConfigured(uint256 chainId);

    struct NetworkConfig {
        address priceFeed;
    }

    NetworkConfig localNetworkConfig;

    mapping(uint256 chainid => NetworkConfig) networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAINID] = getSepoliaEthConfig();
        networkConfigs[MAINNET_CHAINID] = getMainnetEthConfig();
    }

    function getNetworkConfigByChainId(
        uint256 chainId
    ) internal returns (NetworkConfig memory) {
        if (networkConfigs[chainId].priceFeed != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAINID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__ChainIdNotConfigured(chainId);
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getNetworkConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() private pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
            });
    }

    function getMainnetEthConfig() private pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            });
    }

    function getOrCreateAnvilEthConfig()
        private
        returns (NetworkConfig memory)
    {
        if (localNetworkConfig.priceFeed != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_ANSWER
        );
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});

        return localNetworkConfig;
    }
}
