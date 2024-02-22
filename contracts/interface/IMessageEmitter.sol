// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IMessageSpaceStation.sol";

interface IMessageEmitter {
    function minArrivalTime() external view returns (uint64);

    function maxArrivalTime() external view returns (uint64);

    function minGasLimit() external view returns (uint24);

    function maxGasLimit() external view returns (uint24);

    function defaultBridgeMode() external view returns (bytes1);

    function selectedRelayer() external view returns (address);

    struct activateRawMsg {
        uint16[] destChainld;
        uint64 earlistArrivalTime;
        uint64 latestArrivalTime;
        address sender;
        address relayer;
        bytes1[] mode;
        address[] targetContarct;
        uint24[] gasLimit;
        bytes[] message;
        bytes[] aditionParams;
    }

    function emit2LaunchPad(
        IMessageSpaceStation.launchMultiMsgParams calldata params
    ) external payable;

    function emit2LaunchPad(
        IMessageSpaceStation.launchSingleMsgParams calldata params
    ) external payable;

    function converActivateRawMsg(
        activateRawMsg memory rawMsg
    ) external view returns (IMessageSpaceStation.launchMultiMsgParams memory);

    function PacketMessages(
        bytes1[] memory mode,
        uint24[] memory gasLimit,
        address[] memory targetContarct,
        bytes[] memory message
    ) external view returns (bytes[] memory);
}
