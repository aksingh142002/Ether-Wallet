// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // Get Price feed of Ether
    function getPrice() internal view returns(uint) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int price,,,) = priceFeed.latestRoundData();
        return uint(price*1e10);
    }
    // conversion rate of ether to USD
    function conversionRate(uint ethAmount) internal view returns(uint) {
        uint ethPrice = getPrice();
        uint ethAmountInUsd = (ethPrice*ethAmount)/1e18;
        return ethAmountInUsd;
    }
}