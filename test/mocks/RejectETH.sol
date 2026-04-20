// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SimpleBank} from "../../src/SimpleBank.sol";

contract RejectETH {
    SimpleBank bank;

    constructor(address payable _bank) {
        bank = SimpleBank(_bank);
    }

    function depositToBank() external payable {
        bank.deposit{value: msg.value}();
    }

    function withdrawFromBank(uint256 amount) external {
        bank.withdraw(amount);
    }

    receive() external payable {
        revert(); // reject ETH
    }
}
