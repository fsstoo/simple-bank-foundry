#  SimpleBank (Foundry Project)

##  Overview

A minimal ETH bank contract with deposit, withdraw, and excess balance sweeping logic.
Built with a strong focus on **invariant testing and adversarial scenarios**.

---

##  Features

* Deposit & withdraw ETH
* Owner-only sweep of excess funds
* Handles forced ETH (selfdestruct / direct transfer)
* Protection against failed transfers

---

##  Testing

This project includes:

###  Unit Tests

* Deposit / Withdraw
* Sweep logic
* Edge cases (zero values, failures)

###  Invariant Testing (Handler-based)

* Total deposits always match expected state
* Per-user balances tracked via ghost variables
* Contract balance never below deposits
* Forced ETH scenarios tested

---

##  Key Concepts

* Handler-based invariant testing
* Ghost variables (system state tracking)
* Fuzzing with multiple actors
* Adversarial testing (RejectETH, ForceSend)

---

##  Tech Stack

* Solidity ^0.8.20
* Foundry

---

##  Run Locally

```bash
forge install
forge build
forge test
forge coverage
```

---

##  Notes

* `selfdestruct` is used only for testing forced ETH scenarios (EIP-6780 aware)
* Not production-ready, built for learning + security practice

---

##  Project Structure

```text
src/
test/
  ├── unit/
  ├── invariant/
  ├── mocks/
script/
```

---

##  Goal

To deeply understand smart contract testing, invariants, and system-level correctness.
