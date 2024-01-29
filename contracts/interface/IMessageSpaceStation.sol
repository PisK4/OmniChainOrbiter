// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMessageSpaceStation {
    struct paramsLaunch {
        uint64 destChainld;
        uint64 earlistArrivalTime;
        uint64 latestArrivalTime;
        address sender;
        address relayer;
        bytes aditionParams;
        bytes message;
    }

    struct paramsLanding {
        uint64 scrChainld;
        uint64 earlistArrivalTime;
        uint64 latestArrivalTime;
        uint24 nonceLaunch;
        address sender;
        address relayer;
        uint256 value;
        bytes message;
    }

    event SuccessfulLaunch(bytes32 indexed messageId, paramsLaunch params);
    event SuccessfulLanding(bytes32 indexed messageId, paramsLanding params);

    function Launch(
        paramsLaunch calldata params
    ) external payable returns (bytes32 messageId);

    function Landing(
        bytes[] calldata validatorSignatures,
        paramsLanding calldata params
    ) external payable;

    function pause(bool _isPause) external;

    function withdarw(uint256 amount) external;
}
