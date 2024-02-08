// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import {IOrbiterMessageEmitter} from "./IOrbiterMessageEmitter.sol";

interface IMessageSpaceStation {
    struct paramsLaunch {
        uint64[] destChainld;
        uint64 earlistArrivalTime;
        uint64 latestArrivalTime;
        address sender;
        address relayer;
        bytes[] aditionParams;
        bytes[] message;
    }

    struct launchSingleMsgParams {
        uint64 destChainld;
        uint64 earlistArrivalTime;
        uint64 latestArrivalTime;
        address sender;
        address relayer;
        bytes aditionParams;
        bytes message;
    }

    struct paramsLanding {
        uint64 srcChainld;
        uint24 nonceLandingCurrent;
        address sender;
        uint256 value;
        bytes32 messgeId;
        bytes message;
    }

    struct paramsBatchLanding {
        uint64 srcChainld;
        address sender;
        bytes32 messgeId;
    }

    event SuccessfulLaunch(bytes32[] indexed messageId, paramsLaunch params);
    event SuccessfulLaunchSingle(
        bytes32 indexed messageId,
        launchSingleMsgParams params
    );
    event SuccessfulLanding(bytes32 indexed messageId, paramsLanding params);
    event SuccessfulBatchLanding(
        bytes32 indexed messageId,
        paramsBatchLanding params
    );
    event EngineStatusRefreshing(bool isPause);
    event PaymentSystemChanging(address paymentSystemAddress);

    function Launch(
        paramsLaunch calldata params
    ) external payable returns (bytes32[] memory messageId);

    function Launch(
        launchSingleMsgParams calldata params
    ) external payable returns (bytes32 messageId);

    function Landing(
        bytes32 mptRoot,
        uint64 aggregatedEarlistArrivalTime,
        uint64 aggregatedLatestArrivalTime,
        paramsLanding[] calldata params
    ) external payable;

    function Landing(
        bytes32 mptRoot,
        uint64 aggregatedEarlistArrivalTime,
        uint64 aggregatedLatestArrivalTime,
        paramsBatchLanding[] calldata params
    ) external;

    function Pause(bool _isPause) external;

    function Withdarw(uint256 amount) external;

    function SetPaymentSystem(address paymentSystemAddress) external;

    function FetchProtocolFee(
        paramsLaunch calldata params
    ) external view returns (uint256);

    function FetchProtocolFee(
        launchSingleMsgParams calldata params
    ) external view returns (uint256);

    function FetchProtocolFee(
        IOrbiterMessageEmitter.activateRawMsg calldata params
    ) external view returns (uint256);

    function configTrustedSequencer(
        address trustedSequencerAddr,
        bool state
    ) external;
}
