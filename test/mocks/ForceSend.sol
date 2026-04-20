// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Forces ETH into a contract without calling its functions
/// @dev Uses selfdestruct. Post-Cancun (EIP-6780), this no longer deletes the contract
/// but still transfers ETH, which is sufficient for testing forced ETH scenarios.
contract ForceSend {
    constructor() payable {}

    function attack(address target) external {
        selfdestruct(payable(target));
    }
}
