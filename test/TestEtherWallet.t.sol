// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployEtherWallet} from "../script/DeployEtherWallet.s.sol";
import {EtherWallet} from "../src/EtherWallet.sol";

contract TestEtherWallet is Test {
    // Variables for testing
    address USER = makeAddr("user");
    address USER2 = makeAddr("user2");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    bytes constant RANDOM_DATA = "Random Data";

    address deployer;
    EtherWallet test_EtherWallet;

    // Setup function to deploy the contract and fund test accounts
    function setUp() external {
        DeployEtherWallet deploy = new DeployEtherWallet();
        test_EtherWallet = deploy.run();
        deployer = msg.sender;

        vm.deal(USER, STARTING_BALANCE);
        vm.deal(USER2, STARTING_BALANCE);
    }

    // Test the contract's constructor settings
    function test_OwnerIsSender() public view {
        // Verify that the contract owner is the deployer
        assertEq(test_EtherWallet.getOwner(), deployer);
        // Verify that the contract is not paused initially
        assertEq(test_EtherWallet.getPauseStatus(), false);
    }

    // Test the minimum USD value requirement
    function test_MinimumUSD() public view {
        // Verify that the minimum USD required is 5e18
        assertEq(test_EtherWallet.MINIMUM_USD(), 5e18);
    }

    // Test fetching the version of the price feed
    function test_PriceFeedVersion() public view {
        uint256 version = test_EtherWallet.getVersion();
        assertEq(version, 4);
    }

    // Test funding the contract with insufficient Ether
    function test_FundWithoutEnoughETH() public {
        vm.startPrank(USER);
        vm.expectRevert(bytes("Insufficient Amount!!!"));
        test_EtherWallet.fund{value: 1e15}(); // Send less than MINIMUM_USD
        vm.stopPrank();
    }

    // Test updating fund records
    function test_FundsUpdate() public {
        vm.startPrank(USER);

        // Expect the Funded event to be emitted
        vm.expectEmit(true, true, true, true);
        emit EtherWallet.Funded(USER, SEND_VALUE);

        // Fund the contract
        test_EtherWallet.fund{value: SEND_VALUE}();
        vm.stopPrank();

        // Verify the funded amount is updated correctly
        uint256 fundedAmount = test_EtherWallet.getFunderToFundAmount(USER);
        assertEq(fundedAmount, SEND_VALUE);
    }

    // Test adding funder to the array
    function test_FundAddToArray() public {
        vm.startPrank(USER);
        test_EtherWallet.fund{value: SEND_VALUE}();
        vm.stopPrank();

        // Check the funder is added to array once only
        address funder = test_EtherWallet.getFunder(0);
        assertEq(funder, USER);
        assertEq(test_EtherWallet.getFunderArrayLength(), 1);

        // Test the out-of-bounds case for funders array
        vm.expectRevert(bytes("Index Out of Bounds"));
        test_EtherWallet.getFunder(1);
    }

    // Test contract pause functionality with owner and non-owner
    function test_pauseOnlyOwner() public {
        // Verify the owner is the test contract's sender
        assertEq(test_EtherWallet.getOwner(), deployer);

        // Prank as the owner to pause the contract
        vm.startPrank(deployer);
        test_EtherWallet.pause();
        assertEq(test_EtherWallet.getPauseStatus(), true);

        // Try to pause the contract again (should revert)
        vm.expectRevert(bytes("Contract is paused"));
        test_EtherWallet.pause();
        vm.stopPrank();

        // Prank as a non-owner to attempt funding while the contract is paused
        vm.startPrank(USER);
        vm.expectRevert(bytes("Contract is paused"));
        test_EtherWallet.fund{value: SEND_VALUE}();
        vm.stopPrank();

        // Prank as the owner to unpause the contract
        vm.startPrank(deployer);
        test_EtherWallet.unpause();
        assertEq(test_EtherWallet.getPauseStatus(), false);
        vm.stopPrank();

        // Prank as a non-owner to fund the contract after it has been unpaused
        vm.startPrank(USER);
        test_EtherWallet.fund{value: SEND_VALUE}(); // Should succeed
        vm.stopPrank();
    }

    // Test that non-owners cannot pause the contract
    function test_pauseNotOwner() public {
        vm.startPrank(USER);
        vm.expectRevert(EtherWallet.NotOwner.selector);
        test_EtherWallet.pause();
        vm.stopPrank();
    }

    // Test unpause functionality when the contract is not paused
    function test_unpause() public {
        // Verify the owner is the test contract's sender
        assertEq(test_EtherWallet.getOwner(), deployer);

        // Prank as the owner to unpause the contract while the contract is not paused
        vm.startPrank(deployer);
        vm.expectRevert(bytes("Contract is not paused"));
        test_EtherWallet.unpause();
        vm.stopPrank();
    }

    // Test withdrawing funds by the owner
    function test_WithdrawFundOwner() public {
        vm.startPrank(USER);
        test_EtherWallet.fund{value: SEND_VALUE}();
        vm.stopPrank();
        assertTrue(test_EtherWallet.getBalance() != 0);

        vm.startPrank(test_EtherWallet.getOwner());

        // Expect the Withdrawn event to be emitted
        vm.expectEmit(true, true, true, true);
        emit EtherWallet.Withdrawn(test_EtherWallet.getOwner(), test_EtherWallet.getBalance());

        test_EtherWallet.withdraw();
        vm.stopPrank();

        // Verify that the balance is now 0
        assertEq(test_EtherWallet.getBalance(), 0);
    }

    // Test withdrawing funds by a non-owner (should revert)
    function test_WithdrawFundNotOwner() public {
        vm.startPrank(USER);
        vm.expectRevert(EtherWallet.NotOwner.selector);
        test_EtherWallet.withdraw();
        vm.stopPrank();
    }

    // Test that funder array and mapping are reset after withdrawal
    function test_WithdrawArrayReset() public {
        vm.startPrank(USER);
        test_EtherWallet.fund{value: SEND_VALUE}();
        vm.stopPrank();

        vm.startPrank(USER2);
        test_EtherWallet.fund{value: SEND_VALUE}();
        vm.stopPrank();

        vm.startPrank(test_EtherWallet.getOwner());
        test_EtherWallet.withdraw();
        vm.stopPrank();

        // Verify the funders array is reset
        assertTrue(test_EtherWallet.getFunderArrayLength() == 0);

        // Verify the funded amounts are reset
        uint256 fundedAmount = test_EtherWallet.getFunderToFundAmount(USER);
        assertEq(fundedAmount, 0);
    }

    // Test the contract's balance retrieval function
    function test_getBalance() public {
        vm.startPrank(USER);
        test_EtherWallet.fund{value: SEND_VALUE}();
        vm.stopPrank();

        // Verify that the contract's balance is correct
        assertEq(test_EtherWallet.getBalance(), address(test_EtherWallet).balance);
    }

    // Test if a user has funded the contract
    function test_hasFunded() public {
        vm.startPrank(USER);
        test_EtherWallet.fund{value: SEND_VALUE}();
        vm.stopPrank();

        // Verify that the user has indeed funded
        assertTrue(test_EtherWallet.gethasFunded(USER));
    }

    // Test receiving Ether directly to the contract
    function test_receive() public {
        vm.startPrank(USER);
        (bool success,) = address(test_EtherWallet).call{value: SEND_VALUE}("");
        assertTrue(success);
        vm.stopPrank();

        // Verify the contract's balance and funder records
        uint256 contractBalance = test_EtherWallet.getBalance();
        assertEq(contractBalance, SEND_VALUE);

        uint256 fundedAmount = test_EtherWallet.getFunderToFundAmount(USER);
        assertEq(fundedAmount, SEND_VALUE);
    }

    // Test the fallback function when sending data with Ether
    function test_fallback() public {
        bytes memory randomData = "Random Data";
        vm.startPrank(USER);
        (bool success,) = address(test_EtherWallet).call{value: SEND_VALUE}(randomData);
        assertTrue(success);
        vm.stopPrank();

        // Verify the contract's balance and funder records
        uint256 contractBalance = test_EtherWallet.getBalance();
        assertEq(contractBalance, SEND_VALUE);

        uint256 fundedAmount = test_EtherWallet.getFunderToFundAmount(USER);
        assertEq(fundedAmount, SEND_VALUE);
    }
}
