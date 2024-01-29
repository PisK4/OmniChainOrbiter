// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MessageMonitorLib} from "../MessageMonitor.sol";

interface IMessagePaymentSystem {
    function fetchProtocalFee(
        MessageMonitorLib.paramsLaunch calldata params
    ) external view returns (uint256);
}
