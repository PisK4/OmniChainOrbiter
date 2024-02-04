// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "./IMessageSpaceStation.sol";

interface IMessageVerificationSystem {
    function verifyLaunchMessage(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        IMessageSpaceStation.paramsLaunch[] calldata params,
        bytes[] calldata launchParamsSignatures
    ) external view;
}
