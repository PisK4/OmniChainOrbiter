// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import {MessageMonitorLib} from "../MessageMonitor.sol";

interface IMessageSpaceStation {
    event SuccessfulLaunch(
        bytes32 indexed messageId,
        MessageMonitorLib.paramsLaunch params
    );
    event SuccessfulLanding(
        bytes32 indexed messageId,
        MessageMonitorLib.paramsLanding params
    );

    function Launch(
        MessageMonitorLib.paramsLaunch calldata params
    ) external payable returns (bytes32 messageId);

    function Landing(
        bytes[] calldata validatorSignatures,
        MessageMonitorLib.paramsLanding calldata params
    ) external payable;

    function pause(bool _isPause) external;

    function withdarw(uint256 amount) external;

    function setPaymentSystem(address paymentSystemAddress) external;

    function fetchProtocalFee(
        MessageMonitorLib.paramsLaunch calldata params
    ) external view returns (uint256);
}
