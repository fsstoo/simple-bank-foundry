// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SimpleBank} from "../../src/SimpleBank.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantTest is Test {
    SimpleBank bank;
    Handler handler;

    function setUp() public {
        bank = new SimpleBank();
        handler = new Handler(bank);

        targetContract(address(handler));
    }

    /*//////////////////////////////////////////////////////////////
                            INVARIANTS
    //////////////////////////////////////////////////////////////*/

    function invariant_balanceNeverBelowDeposits() public view {
        assert(address(bank).balance >= bank.totalDeposits());
    }

    function invariant_totalDepositsMatchesGhost() public view {
        assertEq(bank.totalDeposits(), handler.ghost_totalDeposits());
    }

    function invariant_userBalancesMatchTotal() public view {
        address[] memory users = handler.getUsers();

        uint256 sum;

        for (uint256 i = 0; i < users.length; i++) {
            sum += bank.balanceOf(users[i]);
        }

        assertEq(sum, bank.totalDeposits());
    }

    function invariant_userBalancesMatchGhost() public view {
        address[] memory users = handler.getUsers();

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];

            assertEq(bank.balanceOf(user), handler.ghost_balanceOf(user));
        }
    }

    function invariant_sumOfGhostBalancesMatchesTotal() public view {
        address[] memory users = handler.getUsers();

        uint256 sum;

        for (uint256 i = 0; i < users.length; i++) {
            sum += handler.ghost_balanceOf(users[i]);
        }

        assertEq(sum, bank.totalDeposits());
    }

    function invariant_excessIsCorrect() public view {
        uint256 expectedExcess = address(bank).balance - bank.totalDeposits();

        assertEq(bank.getExcessBalance(), expectedExcess);
    }
}
