// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMessageVerificationSystem {
    function verifyProofs(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) external view returns (bool);
}
