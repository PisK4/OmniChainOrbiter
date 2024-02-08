// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "./IMessageSpaceStation.sol";
import {IOrbiterMessageEmitter} from "./IOrbiterMessageEmitter.sol";

interface IMessagePaymentSystem {
    function fetchProtocolFee_(
        IMessageSpaceStation.paramsLaunch calldata params
    ) external view returns (uint256);

    function fetchProtocolFee_(
        IMessageSpaceStation.launchSingleMsgParams calldata params
    ) external view returns (uint256);

    function fetchProtocolFee_(
        IOrbiterMessageEmitter.activateRawMsg calldata params
    ) external view returns (uint256);
}
