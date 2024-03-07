// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

interface IMessageEvent is IMessageStruct {
    event SuccessfulLaunchMessages(
        bytes32[] indexed messageId,
        launchMultiMsgParams params
    );
    event SuccessfulLaunchMessage(
        uint64 indexed nonce,
        launchSingleMsgParams params
    );
    event SuccessfulLanding(
        bytes32 indexed messageId,
        InteractionLanding params
    );
    event SuccessfulBatchLanding(
        bytes32 indexed messageId,
        PostingLanding params
    );
    event EngineStatusRefreshing(bool isPause);
    event PaymentSystemChanging(address paymentSystemAddress);
}
