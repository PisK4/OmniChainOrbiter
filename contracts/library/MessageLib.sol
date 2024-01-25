// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library MessageLib {
    struct launchParams {
        uint64 destChainld;
        uint64 earlistArrivalTime;
        uint64 latestArrivalTime;
        address sender;
        address relayer;
        bytes aditionParams;
        bytes message;
    }

    struct landParams {
        uint64 scrChainld;
        uint64 earlistArrivalTime;
        uint64 latestArrivalTime;
        address sender;
        address receiver;
        address relayer;
        bytes aditionParams;
        bytes message;
    }
}
