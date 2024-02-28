// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMessageStruct {
    struct launchSingleMsgParams {
        uint64 earlistArrivalTime;
        uint64 latestArrivalTime;
        address relayer;
        address sender;
        uint16 destChainld;
        bytes aditionParams;
        bytes message;
    }

    struct launchMultiMsgParams {
        uint64 earlistArrivalTime;
        uint64 latestArrivalTime;
        address relayer;
        address sender;
        uint16[] destChainld;
        bytes[] aditionParams;
        bytes[] message;
    }

    struct paramsLanding {
        uint16 srcChainld;
        uint24 nonceLandingCurrent;
        address sender;
        uint256 value;
        bytes32 messgeId;
        bytes message;
    }

    struct paramsBatchLanding {
        uint16 srcChainld;
        address sender;
        bytes32 messgeId;
    }
}
