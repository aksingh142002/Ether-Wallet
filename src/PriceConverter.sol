// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // Get Price feed of Ether
    function getPrice(AggregatorV3Interface feed) internal view returns (uint) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feed);
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint(price * 1e10);
    }

    // conversion rate of ether to USD
    function conversionRate(
        uint ethAmount,
        AggregatorV3Interface feed
    ) internal view returns (uint) {
        uint ethPrice = getPrice(feed);
        uint ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}
