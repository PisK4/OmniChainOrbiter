// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMessageSpaceStation {
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

    function Launch(
        launchParams calldata params
    ) external payable returns (bytes32 messageId);

    function Land(
        bytes[] calldata validatorSignatures,
        landParams calldata params
    ) external;
}
