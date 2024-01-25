// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IOrbiterStation {
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
        uint24 launchNonce;
        address sender;
        address relayer;
        bytes message;
    }

    function launch(
        launchParams calldata params
    ) external payable returns (bytes32 messageId);

    function land(
        bytes[] calldata validatorSignatures,
        landParams calldata params
    ) external;
}
