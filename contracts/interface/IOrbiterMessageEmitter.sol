// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IMessageSpaceStation.sol";

interface IOrbiterMessageEmitter {
    struct activateRawMsg {
        uint64[] destChainld;
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
