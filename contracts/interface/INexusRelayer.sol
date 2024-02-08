// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "./IMessageSpaceStation.sol";

interface INexusRelayer {
    event LaunchMessageVerified(
        IMessageSpaceStation.launchMultiMsgParams[] indexed params
    );

    function verifyLaunchMessage(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        IMessageSpaceStation.launchMultiMsgParams[] calldata params,
        bytes[] calldata launchParamsSignatures
    ) external;
}
