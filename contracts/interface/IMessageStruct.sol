// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMessageStruct {
    struct launchSingleMsgParams {
        uint64 earlistArrivalTimestamp;
        uint64 latestArrivalTimestamp;
        address relayer;
        address sender;
        uint16 destChainld;
        bytes aditionParams;
        bytes message;
    }

    struct launchMultiMsgParams {
        uint64 earlistArrivalTimestamp;
        uint64 latestArrivalTimestamp;
        address relayer;
        address sender;
        uint16[] destChainld;
        bytes[] aditionParams;
        bytes[] message;
    }

    struct InteractionLanding {
        uint16 srcChainld;
        uint24 nonceLandingCurrent;
        address sender;
        uint256 value;
        bytes32 messgeId;
        bytes message;
    }

    struct PostingLanding {
        uint16 srcChainld;
        address sender;
        bytes32 messgeId;
    }

    struct RelayerSignedMessage {
        bytes32 srcTxHash;
        bytes32 destTxHash;
        uint24[] nonceLaunch;
        launchMultiMsgParams params;
    }
}
