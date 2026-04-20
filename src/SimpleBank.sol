// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SimpleBank
 * @author FSTO
 * @notice A minimal ETH bank contract that allows users to deposit and withdraw ETH securely.
 * @dev Uses CEI pattern and ReentrancyGuard for security.
 *
 * Invariant:
 * - address(this).balance >= totalDeposits
 *
 * Note:
 * - ETH sent via `receive()` is treated as excess (not tracked in deposits).
 */
contract SimpleBank is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error SimpleBank__InsufficientBalance();
    error SimpleBank__ZeroAmount();
    error SimpleBank__TransferFailed();
    error SimpleBank__NoExcessBalance();
    error SimpleBank__NotOwner();
    error SimpleBank__InvalidAddress();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Total ETH deposited by users
    uint256 public totalDeposits;

    /// @notice Owner of the contract
    address public owner;

    /// @notice Tracks user balances
    mapping(address => uint256) public balanceOf;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a user deposits ETH
    event Deposit(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws ETH
    event Withdraw(address indexed user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Restricts function to contract owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert SimpleBank__NotOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the deployer as the owner
    constructor() {
        owner = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit ETH into the bank
     * @dev Updates user balance and total deposits
     */
    function deposit() external payable {
        if (msg.value == 0) revert SimpleBank__ZeroAmount();

        balanceOf[msg.sender] += msg.value;
        totalDeposits += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw ETH from the bank
     * @param amount Amount of ETH to withdraw
     * @dev Uses CEI pattern and nonReentrant modifier
     */
    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert SimpleBank__ZeroAmount();
        if (balanceOf[msg.sender] < amount) revert SimpleBank__InsufficientBalance();

        balanceOf[msg.sender] -= amount;
        totalDeposits -= amount;

        emit Withdraw(msg.sender, amount);

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert SimpleBank__TransferFailed();
    }

    /**
     * @notice Returns excess ETH in the contract
     * @dev Excess = contract balance - totalDeposits
     */
    function getExcessBalance() external view returns (uint256) {
        uint256 currentBalance = address(this).balance;

        if (currentBalance <= totalDeposits) {
            return 0;
        }

        return currentBalance - totalDeposits;
    }

    /**
     * @notice Allows owner to withdraw excess ETH
     * @param to Address receiving the excess funds
     */
    function sweep(address to) external onlyOwner {
        if (to == address(0)) revert SimpleBank__InvalidAddress();

        uint256 currentBalance = address(this).balance;

        if (currentBalance <= totalDeposits) {
            revert SimpleBank__NoExcessBalance();
        }

        uint256 excess = currentBalance - totalDeposits;

        (bool success,) = to.call{value: excess}("");
        if (!success) {
            revert SimpleBank__TransferFailed();
        }
    }

    /**
     * @notice Returns balance Of a user
     * @param Of Address to query
     */
    function getBalance(address Of) external view returns (uint256) {
        return balanceOf[Of];
    }

    /**
     * @notice Returns total deposited ETH
     */
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }

    /**
     * @notice Accepts direct ETH transfers
     * @dev ETH sent here is considered excess (not tracked in deposits)
     */
    receive() external payable {}
}
