//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import {Test} from "forge-std/Test.sol";
import {DeployEtherWallet} from "../script/DeployEtherWallet.s.sol";
import {EtherWallet} from "../src/EtherWallet.sol";

contract TestEtherWallet is Test {
    // fakes
    address USER = makeAddr("user");
    address USER2 = makeAddr("user2");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    EtherWallet test_EtherWallet;

    function setUp() external {
        // test_EtherWallet = new EtherWallet(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployEtherWallet deploy = new DeployEtherWallet();
        test_EtherWallet = deploy.run();
        vm.deal(USER, STARTING_BALANCE);
        vm.deal(USER2, STARTING_BALANCE);
    }

    function test_unpause() public {
        // Verify the owner is the test contract's sender
        assertEq(test_EtherWallet.getOwner(), msg.sender);

        // Prank as the owner to unpause the contract while the contract is not paused
        vm.startPrank(msg.sender);
        vm.expectRevert(bytes("Contract is not paused"));
        test_EtherWallet.unpause();
        vm.stopPrank();
    }

    function test_MinimumUSD() public view {
        assertEq(test_EtherWallet.MINIMUM_USD(), 5e18);
    }

    function test_OwnerIsSender() public view {
        assertEq(test_EtherWallet.getOwner(), msg.sender);
        assertEq(test_EtherWallet.getPauseStatus(), false);
    }

    function test_PriceFeedVersion() public view {
        uint256 version = test_EtherWallet.getVersion();
        assertEq(version, 4);
    }

    function test_FundWithoutEnoughETH() public {
        // Ensure the fund function reverts if less than MINIMUM_USD is sent
        vm.startPrank(USER);
        vm.expectRevert(bytes("Insufficient Amount!!!"));
        test_EtherWallet.fund{value: 1e15}(); // Send less than MINIMUM_USD
        vm.stopPrank();
    }

    function test_FundsUpdate() public {
        // Set up the prank to simulate USER as the sender
        vm.startPrank(USER);

        // Expect an event to be emitted
        vm.expectEmit(true, true, true, true);
        emit EtherWallet.Funded(USER, SEND_VALUE);

        // Call the fund function
        test_EtherWallet.fund{value: SEND_VALUE}();

        // Stop the prank
        vm.stopPrank();

        // Check that the funded amount is updated correctly
        uint256 fundedAmount = test_EtherWallet.getFunderToFundAmount(USER);
        assertEq(fundedAmount, SEND_VALUE);
    }

    function test_FundAddToArray() public {
        vm.startPrank(USER);
        test_EtherWallet.fund{value: SEND_VALUE}();
        vm.stopPrank();

        // Check the funder is added to array once only
        address funder = test_EtherWallet.getFunder(0);
        assertEq(funder, USER);
        assertEq(test_EtherWallet.getFunderArrayLength(), 1);

        //check funder out of bound case
        vm.expectRevert(bytes("Index Out of Bounds"));
        test_EtherWallet.getFunder(1);
    }

    function test_pauseOnlyOwner() public {
        // Verify the owner is the test contract's sender
        assertEq(test_EtherWallet.getOwner(), msg.sender);

        // Prank as the owner to pause the contract
        vm.startPrank(msg.sender);
        test_EtherWallet.pause();
        assertEq(test_EtherWallet.getPauseStatus(), true);

        // If owner try to pause the contract again

        vm.expectRevert(bytes("Contract is paused"));
        test_EtherWallet.pause();
        vm.stopPrank();

        // Prank as a non-owner to attempt funding while the contract is paused
        vm.startPrank(USER);
        vm.expectRevert(bytes("Contract is paused"));
        test_EtherWallet.fund{value: SEND_VALUE}();
        vm.stopPrank();

        // Prank as the owner to unpause the contract
        vm.startPrank(msg.sender);
        test_EtherWallet.unpause();
        assertEq(test_EtherWallet.getPauseStatus(), false);
        vm.stopPrank();

        // Prank as a non-owner to fund the contract after it has been unpaused
        vm.startPrank(USER);
        test_EtherWallet.fund{value: SEND_VALUE}(); // Should succeed
        vm.stopPrank();
    }

    function test_pauseNotOwner() public {
        // Prank as a non-owner and expect a revert with the NotOwner error
        vm.startPrank(USER);
        vm.expectRevert(EtherWallet.NotOwner.selector);
        test_EtherWallet.pause();
        vm.stopPrank();
    }

    // Need correction of balance 0
    function test_WithdrawFundOwner() public {
        vm.startPrank(USER);
        test_EtherWallet.fund{value: SEND_VALUE}();
        vm.stopPrank();
        assertTrue(test_EtherWallet.getBalance() != 0);

        vm.startPrank(test_EtherWallet.getOwner());

        // Expect an event to be emitted
        vm.expectEmit(true, true, true, true);
        emit EtherWallet.Withdrawn(
            test_EtherWallet.getOwner(),
            test_EtherWallet.getBalance()
        );

        // vm.expectRevert(bytes("Withdrawal Failed!!!"));
        test_EtherWallet.withdraw();
        vm.stopPrank();

        assertEq(test_EtherWallet.getBalance(), 0);
    }

    function test_WithdrawFundNotOwner() public {
        vm.startPrank(USER);
        vm.expectRevert(EtherWallet.NotOwner.selector);
        test_EtherWallet.withdraw();
        vm.stopPrank();
    }

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

        assertTrue(test_EtherWallet.getFunderArrayLength() == 0);
        // Check that the funded amount is updated correctly
        uint256 fundedAmount = test_EtherWallet.getFunderToFundAmount(USER);
        assertEq(fundedAmount, 0);
    }

    function test_getBalance() public {
        vm.startPrank(USER);
        test_EtherWallet.fund{value: SEND_VALUE}();
        vm.stopPrank();
        assertEq(
            test_EtherWallet.getBalance(),
            address(test_EtherWallet).balance
        );
    }

    function test_hasFunded() public {
        vm.startPrank(USER);
        test_EtherWallet.fund{value: SEND_VALUE}();
        vm.stopPrank();

        assertTrue(test_EtherWallet.gethasFunded(USER));
    }

    // function test_funder() public {
    //     vm.startPrank(USER);
    //     test_EtherWallet.fund{value: SEND_VALUE}();
    //     vm.stopPrank();

    //     address funder = test_EtherWallet.getFunder(0);
    //     assertEq(funder, USER);
    // }

    function test_receive() public {
        vm.startPrank(USER);
        (bool success, ) = address(test_EtherWallet).call{value: SEND_VALUE}(
            ""
        );
        assertTrue(success);
        vm.stopPrank();

        uint256 contractBalance = test_EtherWallet.getBalance();
        assertEq(contractBalance, SEND_VALUE);

        // Check that the funded amount is updated correctly
        uint256 fundedAmount = test_EtherWallet.getFunderToFundAmount(USER);
        assertEq(fundedAmount, SEND_VALUE);
    }

    function test_fallback() public {
        bytes memory randomData = "Random Data";
        vm.startPrank(USER);
        (bool success, ) = address(test_EtherWallet).call{value: SEND_VALUE}(
            randomData
        );
        assertTrue(success);
        vm.stopPrank();

        uint256 contractBalance = test_EtherWallet.getBalance();
        assertEq(contractBalance, SEND_VALUE);

        // Check that the funded amount is updated correctly
        uint256 fundedAmount = test_EtherWallet.getFunderToFundAmount(USER);
        assertEq(fundedAmount, SEND_VALUE);
    }
}
