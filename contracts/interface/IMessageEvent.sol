// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

interface IMessageEvent is IMessageStruct {
    /// @notice Event emitted when a  message which attempts to cross-chain is submitted to LaunchPad contract
    event SuccessfulLaunchMessages(
        uint24[] indexed nonce,
        launchMultiMsgParams params
    );

    /// @notice Event emitted when a  message which attempts to cross-chain is submitted to LaunchPad contract
    event SuccessfulLaunchMessages2(
        uint24 indexed nonce,
        launchMultiMsgParams params
    );

    /// @notice Event emitted when a  message which attempts to cross-chain is submitted to LaunchPad contract
    event SuccessfulLaunchMessage(
        uint64 indexed nonce,
        launchSingleMsgParams params
    );

    /// @notice Event emitted when a cross-chain message is submitted from source chain to target chain
    event SuccessfulLanding(
        bytes32 indexed messageId,
        InteractionLanding params
    );

    /// @notice Event emitted when a cross-chain message is submitted from source chain to target chain
    event SuccessfulBatchLanding(
        bytes32 indexed messageId,
        PostingLanding params
    );

    /// @notice Event emitted when protocol status is changed, such as pause or resume
    event EngineStatusRefreshing(bool indexed isPause);

    /// @notice Event emitted when protocol fee calculation is changed
    event PaymentSystemChanging(address indexed paymentSystemAddress);

    /// @notice Event emitted when protocol fee has been withdrawn
    event WithdrawRequest(uint256 indexed amount);

    /// @notice Event emitted when protocol fee manager change sequencer status
    event SequencerStatusChanging(address indexed sequencerAddress, bool state);
}
