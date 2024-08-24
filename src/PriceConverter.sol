// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // Get Price feed of Ether
    function getPrice(AggregatorV3Interface feed) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feed);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    // conversion rate of ether to USD
    function conversionRate(uint256 ethAmount, AggregatorV3Interface feed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(feed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}
