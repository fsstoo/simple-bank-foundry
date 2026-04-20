// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {SimpleBank} from "../src/SimpleBank.sol";

/**
 * @title DeploySimpleBank
 * @author FSTO
 * @notice Deployment script for SimpleBank contract
 * @dev Uses Foundry's scripting system to broadcast transactions
 */
contract DeploySimpleBank is Script {
    /**
     * @notice Deploys the SimpleBank contract
     * @return bank The deployed SimpleBank instance
     */
    function run() external returns (SimpleBank bank) {
        vm.startBroadcast();

        bank = new SimpleBank();

        vm.stopBroadcast();

        return bank;
    }
}
