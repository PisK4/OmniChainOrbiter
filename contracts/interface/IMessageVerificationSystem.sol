// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "./IMessageSpaceStation.sol";

interface IMessageVerificationSystem {
    event LaunchMessageVerified(
        IMessageSpaceStation.paramsLaunch[] indexed params
    );

    function verifyLaunchMessage(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        IMessageSpaceStation.paramsLaunch[] calldata params,
        bytes[] calldata launchParamsSignatures
    ) external;
}
