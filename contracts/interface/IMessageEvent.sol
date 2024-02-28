// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

interface IMessageEvent is IMessageStruct {
    event SuccessfulLaunch(
        bytes32[] indexed messageId,
        launchMultiMsgParams params
    );
    event SuccessfulLaunchSingle(
        bytes32 indexed messageId,
        launchSingleMsgParams params
    );
    event SuccessfulLanding(bytes32 indexed messageId, paramsLanding params);
    event SuccessfulBatchLanding(
        bytes32 indexed messageId,
        paramsBatchLanding params
    );
    event EngineStatusRefreshing(bool isPause);
    event PaymentSystemChanging(address paymentSystemAddress);
}
