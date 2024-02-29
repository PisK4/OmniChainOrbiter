// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

interface IMessageChannel is IMessageStruct {
    /// @notice LaunchPad is the function that user or DApps send cross-chain message to orther chain
    ///         Once the message is sent, the Relay will validate the message and send it to the target chain
    /// @dev the arguments of the function is packed in the launchMultiMsgParams struct
    ///      message won't be sent if the message is not valid or Protocol fee is not matched
    /// @param params the cross-chain needed params struct
    /// @return messageId the message id of the message
    function Launch(
        launchMultiMsgParams calldata params
    ) external payable returns (bytes32[] memory messageId);

    function Launch(
        launchSingleMsgParams calldata params
    ) external payable returns (bytes32 messageId);

    /// @notice batch landing message to the chain, execute the landing message
    /// @dev trusted sequencer will call this function to send cross-chain message to the Station
    /// @param mptRootNew the merkle patricia trie root of the message
    /// @param aggregatedEarlistArrivalTime the earlist arrival time of the message
    /// @param aggregatedLatestArrivalTime the latest arrival time of the message
    /// @param params the landing message params
    function Landing(
        bytes32 mptRootNew,
        uint64 aggregatedEarlistArrivalTime,
        uint64 aggregatedLatestArrivalTime,
        paramsLanding[] calldata params
    ) external payable;

    /// @notice batch landing message to the chain, only post the landing message to the chain
    /// @dev trusted sequencer will call this function to send cross-chain message to the Station
    /// @param mptRootNew the merkle patricia trie root of the message
    /// @param aggregatedEarlistArrivalTime the earlist arrival time of the message
    /// @param aggregatedLatestArrivalTime the latest arrival time of the message
    /// @param params the landing message params
    function Landing(
        bytes32 mptRootNew,
        uint64 aggregatedEarlistArrivalTime,
        uint64 aggregatedLatestArrivalTime,
        paramsBatchLanding[] calldata params
    ) external;

    /// @dev feel free to call this function before pass message to the Station,
    ///      this method will return the protocol fee that the message need to pay, longer message will pay more
    /// @param params the cross-chain needed params struct
    /// @return protocol fee, the unit is wei
    function EstimateFee(
        launchMultiMsgParams calldata params
    ) external view returns (uint256);

    function EstimateFee(
        launchSingleMsgParams calldata params
    ) external view returns (uint256);

    /// @dev get the message launch nonce of the sender on the specific chain
    /// @param chainId the chain id of the sender
    /// @param sender the address of the sender
    function GetNonceLaunch(
        uint16 chainId,
        address sender
    ) external view returns (uint24);

    /// @dev get the message landing nonce of the sender on the specific chain
    /// @param chainId the chain id of the sender
    /// @param sender the address of the sender
    function GetNonceLanding(
        uint16 chainId,
        address sender
    ) external view returns (uint24);

    /// @dev get the version of the Station
    /// @return the version of the Station, like "v1.0.0"
    function Version() external view returns (string memory);

    /// @dev get the chainId of current Station
    /// @return chainId, defined in the L2SupportLib.sol
    function ChainId() external view returns (uint16);

    function minArrivalTime() external view returns (uint64);

    function maxArrivalTime() external view returns (uint64);
}
