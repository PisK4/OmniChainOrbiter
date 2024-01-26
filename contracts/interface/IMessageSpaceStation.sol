// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMessageSpaceStation {
    struct LaunchParams {
        uint64 destChainld;
        uint64 earlistArrivalTime;
        uint64 latestArrivalTime;
        address sender;
        address relayer;
        bytes aditionParams;
        bytes message;
    }

    struct LandParams {
        uint64 scrChainld;
        uint64 earlistArrivalTime;
        uint64 latestArrivalTime;
        uint24 launchNonce;
        address sender;
        address relayer;
        bytes message;
    }

    event LaunchEvent(bytes32 indexed messageId, LaunchParams params);
    event LandEvent(bytes32 indexed messageId, LandParams params);

    function Launch(
        LaunchParams calldata params
    ) external payable returns (bytes32 messageId);

    function Land(
        bytes[] calldata validatorSignatures,
        LandParams calldata params
    ) external;

    function pause(bool _isPause) external;

    function withdarw(uint256 amount) external;
}
