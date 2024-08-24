// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// Recheck funder array, s_funderToFundAmount  working in remix & test case

contract EtherWallet {
    // Custom Error
    error NotOwner();

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    bool private s_paused; // State variable to track if the contract is paused

    // List of funders and mapping to track how much each address has funded
    address[] private s_funders;
    mapping(address => uint256) private s_funderToFundAmount;
    mapping(address => bool) private s_hasFunded; // Track if an address has already funded

    address private immutable i_owner; // Owner of the contract, set at deployment

    AggregatorV3Interface private s_priceFeed;

    // Events to log actions on the blockchain
    event Funded(address indexed funder, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    // Constructor sets the contract owner and initializes the paused state
    constructor(address feed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(feed);
        s_paused = false;
    }

    // Modifier to restrict access to owner-only functions
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // Modifier to ensure a function can only be called when the contract is not paused
    modifier whenNotPaused() {
        require(!s_paused, "Contract is paused");
        _;
    }

    // Modifier to ensure a function can only be called when the contract is paused
    modifier whenPaused() {
        require(s_paused, "Contract is not paused");
        _;
    }

    // Function to fund the contract, ensuring the value meets the minimum USD requirement
    function fund() public payable whenNotPaused {
        require(
            msg.value.conversionRate(s_priceFeed) >= MINIMUM_USD,
            "Insufficient Amount!!!"
        );
        s_funderToFundAmount[msg.sender] += msg.value; // Update the funder's balance

        // NOT WORKING:------
        // Add the funder to the funders array if they haven't funded before
        if (!s_hasFunded[msg.sender]) {
            s_funders.push(msg.sender);
            s_hasFunded[msg.sender] = true;
        }
        emit Funded(msg.sender, msg.value); // Emit a funded event
    }

    // Function to pause the contract, can only be called by the owner
    function pause() public onlyOwner whenNotPaused {
        s_paused = true;
    }

    // Function to unpause the contract, can only be called by the owner
    function unpause() public onlyOwner whenPaused {
        s_paused = false;
    }

    // Function to get the current balance of the contract in Ether
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Function to get the current price feed version
    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    // Function to withdraw all funds, only accessible to the owner and when the contract is not paused
    function withdraw() public onlyOwner whenNotPaused {
        uint256 balance = address(this).balance; // Store the balance before modifying state

        // Reset each funder's balance
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_funderToFundAmount[funder] = 0;
        }
        s_funders = new address[](0); // Clear the funders array

        // Transfer the contract's balance to the owner
        (bool callSuccess, ) = payable(msg.sender).call{value: balance}("");
        require(callSuccess, "Withdrawal Failed!!!");

        emit Withdrawn(msg.sender, balance); // Emit a withdrawn event
    }

    // Fallback function to handle plain Ether transfers, directs to the fund function
    receive() external payable {
        fund();
    }

    // Fallback function to handle calls with data, directs to the fund function
    fallback() external payable {
        fund();
    }

    // <---  Getters   --->

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getPauseStatus() external view returns (bool) {
        return s_paused;
    }

    function getFunder(uint256 index) external view returns (address) {
        require(index < s_funders.length, "Index Out of Bounds");
        return s_funders[index];
    }

    function getFunderArrayLength() external view returns (uint256) {
        return s_funders.length;
    }

    function getFunderToFundAmount(
        address funder
    ) external view returns (uint256) {
        return s_funderToFundAmount[funder];
    }

    function gethasFunded(address funder) external view returns (bool) {
        return s_hasFunded[funder];
    }
}
