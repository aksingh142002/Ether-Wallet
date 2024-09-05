// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

/// @title EtherWallet - A smart contract wallet for handling Ether deposits and withdrawals
/// @notice This contract allows users to fund the wallet, while only the owner can withdraw funds.
/// @dev The contract uses Chainlink's price feed to enforce a minimum funding amount in USD.

contract EtherWallet {
    using PriceConverter for uint256;

    // Constants
    uint256 public constant MINIMUM_USD = 5e18; // Minimum USD equivalent to fund the contract

    // State Variables
    bool private s_paused; // Tracks if the contract is paused
    address private immutable i_owner; // Owner of the contract, set at deployment
    AggregatorV3Interface public immutable s_priceFeed; // Chainlink Price Feed

    // Mappings and Arrays
    address[] private s_funders; // List of unique funders
    mapping(address => uint256) private s_funderToFundAmount; // Tracks the amount funded by each address
    mapping(address => bool) private s_hasFunded; // Tracks if an address has already funded

    // Events
    event Funded(address indexed funder, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    // Custom Errors
    error NotOwner();
    error PausedError();
    error NotPausedError();
    error FundError();
    error WithdrawError();
    error IndexOutOfBoundsError();

    // Modifiers

    /// @dev Restricts function access to only the contract owner.
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    /// @dev Ensures the function is callable only when the contract is not paused.
    modifier whenNotPaused() {
        if (s_paused) {
            revert PausedError();
        }
        _;
    }

    /// @dev Ensures the function is callable only when the contract is paused.
    modifier whenPaused() {
        if (!s_paused) {
            revert NotPausedError();
        }
        _;
    }

    // Constructor

    /// @param feed The address of the Chainlink price feed contract.
    constructor(address feed) {
        i_owner = msg.sender; // Set the owner to the deployer
        s_priceFeed = AggregatorV3Interface(feed); // Initialize the price feed
        s_paused = false; // Start the contract in an unpaused state
    }

    // Core Functions

    /// @notice Allows users to fund the contract with a minimum USD equivalent amount.
    /// @dev Ensures the amount sent meets the minimum USD requirement.
    function fund() public payable whenNotPaused {
        if (msg.value.conversionRate(s_priceFeed) < MINIMUM_USD) {
            revert FundError();
        }
        s_funderToFundAmount[msg.sender] += msg.value;

        // Add the funder to the funders array if they haven't funded before
        if (!s_hasFunded[msg.sender]) {
            s_funders.push(msg.sender);
            s_hasFunded[msg.sender] = true;
        }

        emit Funded(msg.sender, msg.value);
    }

    /// @notice Pauses the contract, preventing further funding.
    /// @dev Only callable by the owner when the contract is not paused.
    function pause() external onlyOwner whenNotPaused {
        s_paused = true;
    }

    /// @notice Unpauses the contract, allowing further funding.
    /// @dev Only callable by the owner when the contract is paused.
    function unpause() external onlyOwner whenPaused {
        s_paused = false;
    }

    /// @notice Withdraws all Ether from the contract to the owner.
    /// @dev Resets the funders' balances and the funders array.
    function withdraw() external onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        uint256 fundersLength = s_funders.length;

        // Reset each funder's balance
        for (uint256 funderIndex; funderIndex < fundersLength;) {
            address funder = s_funders[funderIndex];
            s_funderToFundAmount[funder] = 0;
            unchecked {
                ++funderIndex;
            }
        }
        s_funders = new address[](0); // Clear the funders array

        // Transfer the contract's balance to the owner
        (bool callSuccess,) = payable(msg.sender).call{value: balance}("");
        if (!callSuccess) {
            revert WithdrawError();
        }

        emit Withdrawn(msg.sender, balance);
    }

    // Fallback Functions

    /// @notice Fallback function to handle plain Ether transfers.
    /// @dev Directs the transfer to the fund function.
    receive() external payable {
        fund();
    }

    /// @notice Fallback function to handle calls with data.
    /// @dev Directs the call to the fund function.
    fallback() external payable {
        fund();
    }

    // Getters

    /// @return The owner of the contract.
    function getOwner() external view returns (address) {
        return i_owner;
    }

    /// @return The paused status of the contract.
    function getPauseStatus() external view returns (bool) {
        return s_paused;
    }

    /// @param index The index of the funder in the array.
    /// @return The address of the funder at the specified index.
    function getFunder(uint256 index) external view returns (address) {
        if (index > s_funders.length) {
            revert IndexOutOfBoundsError();
        }
        return s_funders[index];
    }

    /// @return The number of unique funders.
    function getFunderArrayLength() external view returns (uint256) {
        return s_funders.length;
    }

    /// @param funder The address of the funder.
    /// @return The amount funded by the specified address.
    function getFunderToFundAmount(address funder) external view returns (uint256) {
        return s_funderToFundAmount[funder];
    }

    /// @param funder The address of the funder.
    /// @return A boolean indicating if the address has funded the contract.
    function gethasFunded(address funder) external view returns (bool) {
        return s_hasFunded[funder];
    }

    /// @return The current balance of the contract in Ether.
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @return The current version of the price feed.
    function getVersion() external view returns (uint256) {
        return s_priceFeed.version();
    }
}
