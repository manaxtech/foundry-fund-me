// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getVersion(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return priceFeed.version();
    }

    function getDecimals(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return uint256(priceFeed.decimals());
    }

    function withDecimals(
        uint256 multiplicand,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return multiplicand * (10 ** getDecimals(priceFeed));
    }

    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethAmountUsdWithDecimals = (ethAmount * getPrice(priceFeed)) /
            1e18;
        return ethAmountUsdWithDecimals;
    }
}
