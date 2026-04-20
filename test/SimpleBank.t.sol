// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DeploySimpleBank} from "../script/DeploySimpleBank.s.sol";
import {SimpleBank} from "../src/SimpleBank.sol";
import {ForceSend} from "../test/mocks/ForceSend.sol";
import {RejectETH} from "../test/mocks/RejectETH.sol";

contract SimpleBankTest is Test {
    SimpleBank bank;
    DeploySimpleBank simpleBank;

    uint256 startingAmount = 100 ether;
    uint256 depositAmount = 10 ether;
    uint256 withdrawAmount = 5 ether;
    uint256 maxAmount = type(uint256).max;

    address owner = msg.sender;
    address user = makeAddr("user");
    address user2 = makeAddr("user2");

    function setUp() public {
        simpleBank = new DeploySimpleBank();
        bank = simpleBank.run();
        vm.deal(user, startingAmount);
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier userDeposited() {
        vm.prank(user);
        bank.deposit{value: depositAmount}();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function testConstructor() public view {
        assertEq(bank.owner(), owner);
    }

    /*//////////////////////////////////////////////////////////////
                              DEPOSIT TESTS
    //////////////////////////////////////////////////////////////*/

    function testDeposit() public {
        assertEq(bank.balanceOf(user), 0);

        vm.prank(user);
        bank.deposit{value: depositAmount}();

        assertEq(bank.balanceOf(user), depositAmount);
        assertEq(bank.getTotalDeposits(), depositAmount);
        assertEq(address(bank).balance, depositAmount);
    }

    function testFuzz_Deposit(uint256 amount) public {
        amount = bound(amount, 1, maxAmount);

        vm.deal(user, amount);

        vm.prank(user);
        bank.deposit{value: amount}();

        assertEq(bank.balanceOf(user), amount);
        assertEq(bank.getTotalDeposits(), amount);
        assertEq(address(bank).balance, amount);
    }

    function testFuzz_MultipleUsersDeposit(uint256 amt1, uint256 amt2) public {
        amt1 = bound(amt1, 1 ether, 50 ether);
        amt2 = bound(amt2, 1 ether, 50 ether);

        vm.deal(user, amt1);
        vm.deal(user2, amt2);

        vm.prank(user);
        bank.deposit{value: amt1}();

        vm.prank(user2);
        bank.deposit{value: amt2}();

        assertEq(bank.balanceOf(user), amt1);
        assertEq(bank.balanceOf(user2), amt2);
        assertEq(bank.getTotalDeposits(), amt1 + amt2);
    }

    function testDepositRevertIfAmountZero() public {
        assertEq(bank.balanceOf(user), 0);

        uint256 zeroAmount = 0 ether;

        vm.prank(user);
        vm.expectRevert(SimpleBank.SimpleBank__ZeroAmount.selector);
        bank.deposit{value: zeroAmount}();

        assertEq(bank.balanceOf(user), zeroAmount);
    }

    /*//////////////////////////////////////////////////////////////
                              WITHDRAW TESTS
    //////////////////////////////////////////////////////////////*/

    function testWithdraw() public userDeposited {
        assertEq(bank.balanceOf(user), depositAmount);

        uint256 userBalanceBefore = user.balance;

        vm.prank(user);
        bank.withdraw(withdrawAmount);

        assertEq(bank.balanceOf(user), depositAmount - withdrawAmount);
        assertEq(user.balance, userBalanceBefore + withdrawAmount);
        assertEq(bank.getTotalDeposits(), depositAmount - withdrawAmount);
        assertEq(address(bank).balance, depositAmount - withdrawAmount);
    }

    function testWithdrawFullBalance() public userDeposited {
        vm.prank(user);
        bank.withdraw(depositAmount);

        assertEq(bank.balanceOf(user), 0);
        assertEq(bank.getTotalDeposits(), 0);
    }

    function testFuzz_Withdraw(uint256 depositAmt, uint256 withdrawAmt) public {
        depositAmt = bound(depositAmt, 1 ether, 100 ether);
        withdrawAmt = bound(withdrawAmt, 1, depositAmt);

        vm.deal(user, depositAmt);

        vm.prank(user);
        bank.deposit{value: depositAmt}();

        uint256 before = user.balance;

        vm.prank(user);
        bank.withdraw(withdrawAmt);

        assertEq(bank.balanceOf(user), depositAmt - withdrawAmt);
        assertEq(user.balance, before + withdrawAmt);
        assertEq(bank.getTotalDeposits(), depositAmt - withdrawAmt);
    }

    function testWithdrawRevertIfAmountZero() public userDeposited {
        assertEq(bank.balanceOf(user), depositAmount);

        uint256 zeroAmount = 0 ether;

        vm.prank(user);
        vm.expectRevert(SimpleBank.SimpleBank__ZeroAmount.selector);
        bank.withdraw(zeroAmount);

        assertEq(bank.balanceOf(user), depositAmount);
    }

    function testWithdrawRevertIfAmountIsGreaterThanBalance() public userDeposited {
        assertEq(bank.balanceOf(user), depositAmount);

        uint256 greaterAmount = 110 ether;

        vm.prank(user);
        vm.expectRevert(SimpleBank.SimpleBank__InsufficientBalance.selector);
        bank.withdraw(greaterAmount);

        assertEq(bank.balanceOf(user), depositAmount);
    }

    function testWithdrawRevertsIfTransferFails() public {
        RejectETH reject = new RejectETH(payable(bank));

        vm.deal(address(reject), 10 ether);

        // deposit from rejecting contract
        reject.depositToBank{value: 5 ether}();

        vm.expectRevert(SimpleBank.SimpleBank__TransferFailed.selector);

        // withdraw triggers failed transfer
        reject.withdrawFromBank(5 ether);
    }

    /*//////////////////////////////////////////////////////////////
                          EXCESS ETH TESTS
    //////////////////////////////////////////////////////////////*/

    function testCalculateExcessBalance() public userDeposited {
        // Force ETH into contract
        vm.deal(address(bank), 20 ether);

        uint256 currentBalance = address(bank).balance;
        uint256 totalDeposits = bank.getTotalDeposits();
        uint256 excessBalance = currentBalance - totalDeposits;

        assertEq(bank.getExcessBalance(), excessBalance);
    }

    function testFuzz__CalculateExcessBalance(uint256 amount) public userDeposited {
        amount = bound(amount, 1, 100000 ether);

        uint256 initialBalance = address(bank).balance;

        // add forced ETH instead of replacing balance
        vm.deal(address(bank), initialBalance + amount);

        uint256 currentBalance = address(bank).balance;
        uint256 totalDeposits = bank.getTotalDeposits();

        uint256 excessBalance = currentBalance - totalDeposits;

        assertEq(bank.getExcessBalance(), excessBalance);
    }

    function test_ForcedEthViaSelfdestruct() public userDeposited {
        ForceSend attacker = new ForceSend{value: 5 ether}();

        attacker.attack(address(bank));

        assertEq(bank.getExcessBalance(), 5 ether);
    }

    function testReceiveCreatesExcess() public {
        vm.deal(user, 5 ether);

        vm.prank(user);
        (bool success,) = address(bank).call{value: 5 ether}("");
        require(success);

        assertEq(bank.getExcessBalance(), 5 ether);
    }

    /*//////////////////////////////////////////////////////////////
                           SWEEP TESTS
    //////////////////////////////////////////////////////////////*/

    function testSweepSuccess() public userDeposited {
        // Force ETH into contract
        vm.deal(address(bank), 20 ether);

        uint256 before = user2.balance;

        vm.prank(owner);
        bank.sweep(user2);

        assertEq(user2.balance, before + 10 ether);
    }

    function testFuzz_Sweep(uint256 excess) public userDeposited {
        excess = bound(excess, 1 ether, 100 ether);

        uint256 initial = address(bank).balance;
        vm.deal(address(bank), initial + excess);

        uint256 before = user2.balance;

        vm.prank(owner);
        bank.sweep(user2);

        assertEq(user2.balance, before + excess);
    }

    function testSweepRevertsIfThereIsNoExcessBalance() public userDeposited {
        // Force ETH into contract
        vm.deal(address(bank), 10 ether);

        vm.prank(owner);
        vm.expectRevert(SimpleBank.SimpleBank__NoExcessBalance.selector);
        bank.sweep(user2);
    }

    function testSweepSuccessIfOnlyOwner() public userDeposited {
        // Force ETH into contract
        vm.deal(address(bank), 10 ether);

        vm.prank(user);
        vm.expectRevert(SimpleBank.SimpleBank__NotOwner.selector);
        bank.sweep(user2);
    }

    function testSweepRevertsIfTransferFails() public userDeposited {
        vm.deal(address(bank), 20 ether);

        RejectETH reject = new RejectETH(payable(bank));

        vm.prank(owner);
        vm.expectRevert(SimpleBank.SimpleBank__TransferFailed.selector);
        bank.sweep(address(reject));
    }

    function testSweepRevertsIfZeroAddress() public userDeposited {
        vm.deal(address(bank), 20 ether);

        vm.prank(owner);
        vm.expectRevert(SimpleBank.SimpleBank__InvalidAddress.selector);
        bank.sweep(address(0));
    }

    /*//////////////////////////////////////////////////////////////
                              GETTER TEST
    //////////////////////////////////////////////////////////////*/

    function testGetUserBalance() public userDeposited {
        assertEq(bank.getBalance(user), depositAmount);
    }

    function invariant_balanceNeverBelowDeposits() public view {
        assert(address(bank).balance >= bank.totalDeposits());
    }
}

