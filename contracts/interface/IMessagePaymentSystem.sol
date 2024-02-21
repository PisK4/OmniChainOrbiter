// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "./IMessageSpaceStation.sol";
import {IMessageEmitter} from "./IMessageEmitter.sol";

interface IMessagePaymentSystem {
    function fetchProtocolFee_(
        IMessageSpaceStation.launchMultiMsgParams calldata params
    ) external view returns (uint256);

    function fetchProtocolFee_(
        IMessageSpaceStation.launchSingleMsgParams calldata params
    ) external view returns (uint256);

    function fetchProtocolFee_(
        IMessageEmitter.activateRawMsg calldata params
    ) external view returns (uint256);
}
