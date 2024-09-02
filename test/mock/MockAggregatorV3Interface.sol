// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title MockV3Aggregator
 * @notice A mock implementation of the Chainlink AggregatorV3Interface
 * @dev This contract is useful for testing smart contracts that interact with price feeds.
 *      It mimics the functionality of an actual Chainlink aggregator but allows you to manually
 *      set prices and round data, making it ideal for unit tests.
 */
contract MockV3Aggregator is AggregatorV3Interface {
    // Constants and state variables
    uint256 public constant version = 4; // Mock version number, matching the Chainlink aggregator's version
    uint8 public immutable decimals; // The number of decimals used by the price feed
    int256 public latestAnswer; // The latest answer (price) provided by the mock
    uint256 public latestTimestamp; // The timestamp of the latest answer
    uint256 public latestRound; // The ID of the latest round

    // Mappings to store historical round data
    mapping(uint256 => int256) public getAnswer; // Maps round ID to the answer
    mapping(uint256 => uint256) public getTimestamp; // Maps round ID to the timestamp
    mapping(uint256 => uint256) private getStartedAt; // Maps round ID to the start time

    /**
     * @notice Constructor to initialize the mock with a given number of decimals and an initial answer.
     * @param _decimals The number of decimals the mock should use
     * @param _initialAnswer The initial price to be set in the mock
     */
    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        updateAnswer(_initialAnswer); // Sets the initial answer and updates state variables
    }

    /**
     * @notice Updates the latest answer with a new value.
     * @param _answer The new price to set as the latest answer
     */
    function updateAnswer(int256 _answer) public {
        latestAnswer = _answer;
        latestTimestamp = block.timestamp;
        latestRound++;
        getAnswer[latestRound] = _answer;
        getTimestamp[latestRound] = block.timestamp;
        getStartedAt[latestRound] = block.timestamp;
    }

    /**
     * @notice Updates the round data manually, useful for simulating specific scenarios.
     * @param _roundId The round ID to update
     * @param _answer The price to set for this round
     * @param _timestamp The timestamp for this round
     * @param _startedAt The start time for this round
     */
    function updateRoundData(uint80 _roundId, int256 _answer, uint256 _timestamp, uint256 _startedAt) public {
        latestRound = _roundId;
        latestAnswer = _answer;
        latestTimestamp = _timestamp;
        getAnswer[latestRound] = _answer;
        getTimestamp[latestRound] = _timestamp;
        getStartedAt[latestRound] = _startedAt;
    }

    /**
     * @notice Returns data for a specific round.
     * @param _roundId The round ID to retrieve data for
     * @return roundId The round ID
     * @return answer The price in this round
     * @return startedAt The start time of the round
     * @return updatedAt The time the price was last updated
     * @return answeredInRound The round ID (same as input)
     */
    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, getAnswer[_roundId], getStartedAt[_roundId], getTimestamp[_roundId], _roundId);
    }

    /**
     * @notice Returns the latest round data.
     * @return roundId The latest round ID
     * @return answer The latest price
     * @return startedAt The start time of the latest round
     * @return updatedAt The time the latest price was last updated
     * @return answeredInRound The latest round ID (same as output roundId)
     */
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (
            uint80(latestRound),
            getAnswer[latestRound],
            getStartedAt[latestRound],
            getTimestamp[latestRound],
            uint80(latestRound)
        );
    }

    /**
     * @notice Returns a static description of the mock aggregator.
     * @return A string description of the contract
     */
    function description() external pure override returns (string memory) {
        return "v0.6/test/mock/MockV3Aggregator.sol";
    }
}
