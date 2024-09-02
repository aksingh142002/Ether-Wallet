// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title PriceConverter - A library for converting Ether amounts to USD using Chainlink Price Feeds.
/// @notice This library is intended for use in contracts that require price conversions between Ether and USD.
/// @dev The library interfaces with the Chainlink price feed to obtain the latest price of Ether in USD.

library PriceConverter {
    /// @notice Retrieves the latest price of Ether in USD from the Chainlink price feed.
    /// @param feed The address of the Chainlink AggregatorV3Interface contract.
    /// @return The latest Ether price in USD, scaled by 1e18.
    function getPrice(AggregatorV3Interface feed) private view returns (uint256) {
        (, int256 price,,,) = feed.latestRoundData(); // Get the latest price
        return uint256(price * 1e10); // Adjust the price to have 18 decimal places
    }

    /// @notice Converts a specified Ether amount to its equivalent in USD using the current price feed data.
    /// @param ethAmount The amount of Ether to convert.
    /// @param feed The address of the Chainlink AggregatorV3Interface contract.
    /// @return The equivalent USD value of the specified Ether amount, scaled by 1e18.
    function conversionRate(uint256 ethAmount, AggregatorV3Interface feed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(feed); // Get the current Ether price in USD
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // Convert Ether to USD
        return ethAmountInUsd;
    }
}
