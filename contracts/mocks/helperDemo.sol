// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MessageMonitorLib} from "../MessageMonitor.sol";
import {Utils} from "../library/Utils.sol";

contract Helper {
    using Utils for bytes;

    function encodeparams(
        MessageMonitorLib.paramsLanding calldata params
    ) external pure returns (bytes32 data) {
        data = abi.encode(params).hash();
    }
}
