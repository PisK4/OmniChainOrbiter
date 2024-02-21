// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "./IMessageSpaceStation.sol";
import {IMessageEmitter} from "./IMessageEmitter.sol";

interface IMessagePaymentSystem {
    function EstimateFee_(
        IMessageSpaceStation.launchMultiMsgParams calldata params
    ) external view returns (uint256);

    function EstimateFee_(
        IMessageSpaceStation.launchSingleMsgParams calldata params
    ) external view returns (uint256);

    function EstimateFee_(
        IMessageEmitter.activateRawMsg calldata params
    ) external view returns (uint256);
}
