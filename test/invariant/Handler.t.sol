// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SimpleBank} from "../../src/SimpleBank.sol";
import {Test} from "forge-std/Test.sol";

contract Handler is Test {
    SimpleBank public bank;

    address[] public users;
    uint256 public ghost_totalDeposits;
    mapping(address => uint256) public ghost_balanceOf;

    constructor(SimpleBank _bank) {
        bank = _bank;

        // create a set of users
        users.push(makeAddr("user1"));
        users.push(makeAddr("user2"));
        users.push(makeAddr("user3"));
    }

    /*//////////////////////////////////////////////////////////////
                            ACTIONS
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 userSeed, uint256 amount) public {
        address user = users[userSeed % users.length];
        amount = bound(amount, 1 ether, 50 ether);

        vm.deal(user, amount);

        vm.prank(user);
        bank.deposit{value: amount}();

        ghost_totalDeposits += amount;
        ghost_balanceOf[user] += amount;
    }

    function withdraw(uint256 userSeed, uint256 amount) public {
        address user = users[userSeed % users.length];

        uint256 balance = bank.balanceOf(user);
        if (balance == 0) return;

        amount = bound(amount, 0, balance);

        vm.prank(user);
        bank.withdraw(amount);

        ghost_totalDeposits -= amount;
        ghost_balanceOf[user] -= amount;
    }

    // simulate forced ETH (like selfdestruct attack)
    function forceSend(uint256 amount) public {
        amount = bound(amount, 1 ether, 50 ether);

        vm.deal(address(this), amount);
        (bool success,) = address(bank).call{value: amount}("");
        require(success);
    }

    function sweep(address to) public {
        if (to == address(0)) return;

        vm.prank(bank.owner());

        try bank.sweep(to) {} catch {}
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW HELPERS
    //////////////////////////////////////////////////////////////*/

    function getUsers() external view returns (address[] memory) {
        return users;
    }
}
