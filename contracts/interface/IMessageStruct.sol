// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMessageStruct {
    struct launchSingleMsgParams {
        uint64 earlistArrivalTimestamp;
        uint64 latestArrivalTimestamp;
        address relayer;
        address sender;
        uint256 value;
        uint64 destChainld;
        bytes aditionParams;
        bytes message;
    }

    struct launchMultiMsgParams {
        uint64 earlistArrivalTimestamp;
        uint64 latestArrivalTimestamp;
        address relayer;
        address sender;
        uint256[] value;
        uint64[] destChainld;
        bytes[] aditionParams;
        bytes[] message;
    }

    struct InteractionLanding {
        uint64 srcChainld;
        uint24 nonceLandingCurrent;
        address sender;
        uint256 value;
        bytes32 messgeId;
        bytes message;
    }

    struct PostingLanding {
        uint64 srcChainld;
        address sender;
        bytes32 messgeId;
    }

    struct SignedMessageStruct {
        uint64 srcChainId;
        uint24[] nonceLaunch;
        bytes32 srcTxHash;
        bytes32 destTxHash;
        IMessageStruct.launchMultiMsgParams params;
    }
}
