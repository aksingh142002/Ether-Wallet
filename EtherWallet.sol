// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract Wallet {
    using PriceConverter for uint;
    
    uint public constant MINIMUM_USD = 5e18;
    bool public paused; // State variable to track if the contract is paused
    
    // List of funders and mapping to track how much each address has funded
    address[] public funders;
    mapping (address => uint) public funderToFundAmount;
    mapping (address => bool) hasFunded; // Track if an address has already funded
    
    address public immutable i_owner; // Owner of the contract, set at deployment

    // Events to log actions on the blockchain
    event Funded(address indexed funder, uint256 amount);
    event Withdrawn(uint256 amount, address indexed to);

    // Constructor sets the contract owner and initializes the paused state
    constructor() {
        i_owner = msg.sender;
        paused = false;
    }

    // Modifier to restrict access to owner-only functions
    modifier onlyOwner {
        if (msg.sender != i_owner) { revert NotOwner(); }
        _;
    }

    // Modifier to ensure a function can only be called when the contract is not paused
    modifier whenNotPaused {
        require(!paused, "Contract is paused");
        _;
    }

    // Modifier to ensure a function can only be called when the contract is paused
    modifier whenPaused {
        require(paused, "Contract is not paused");
        _;
    }

    // Function to fund the contract, ensuring the value meets the minimum USD requirement
    function fund() public payable whenNotPaused {
        require(msg.value.conversionRate() >= MINIMUM_USD, "Insufficient Amount!!!");
        funderToFundAmount[msg.sender] += msg.value; // Update the funder's balance
        
        // Add the funder to the funders array if they haven't funded before
        if (!hasFunded[msg.sender]) {
            funders.push(msg.sender);
            hasFunded[msg.sender] = true;
        }
        emit Funded(msg.sender, msg.value); // Emit a funded event
    }

    // Function to pause the contract, can only be called by the owner
    function pause() public onlyOwner whenNotPaused {
        paused = true;
    }

    // Function to unpause the contract, can only be called by the owner
    function unpause() public onlyOwner whenPaused {
        paused = false;
    }

    // Function to get the current balance of the contract in Ether
    function getBalance() public view returns(uint256) {
        return address(this).balance / 1e18;
    }

    // Function to withdraw all funds, only accessible to the owner and when the contract is not paused
    function withdraw() public onlyOwner whenNotPaused {
        uint256 balance = address(this).balance; // Store the balance before modifying state

        // Reset each funder's balance
        for (uint funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            funderToFundAmount[funder] = 0;
        }
        funders = new address[](0) ; // Clear the funders array

        // Transfer the contract's balance to the owner
        (bool callSuccess, ) = payable(msg.sender).call{value: balance}("");
        require(callSuccess, "Withdrawal Failed!!!");
        
        emit Withdrawn(balance, msg.sender); // Emit a withdrawn event
    }

    // Fallback function to handle plain Ether transfers, directs to the fund function
    receive() external payable {
        fund();
    }

    // Fallback function to handle calls with data, directs to the fund function
    fallback() external payable {
        fund();
    }
}
