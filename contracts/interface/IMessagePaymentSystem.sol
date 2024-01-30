// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "./IMessageSpaceStation.sol";

interface IMessagePaymentSystem {
    function fetchProtocalFee_(
        IMessageSpaceStation.paramsLaunch calldata params
    ) external view returns (uint256);
}
