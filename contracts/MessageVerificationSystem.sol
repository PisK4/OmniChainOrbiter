// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {IMessageVerificationSystem} from "./interface/IMessageVerificationSystem.sol";
import {IMessageSpaceStation} from "./interface/IMessageSpaceStation.sol";
import {Utils} from "./library/Utils.sol";
import {Errors} from "./library/Errors.sol";

contract MessageVerificationSystem is IMessageVerificationSystem, Ownable {
    using MessageHashUtils for bytes32;
    using Utils for bytes;
    using ECDSA for bytes32;

    constructor() Ownable(msg.sender) {}

    function verifyLaunchMessage(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        IMessageSpaceStation.paramsLaunch[] calldata params,
        bytes[] calldata launchParamsSignatures
    ) external pure override {
        bytes32[] memory leaves = new bytes32[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            leaves[i] = abi.encode(params[i]).hash();
        }
        _validateSignature(abi.encode(params).hash(), launchParamsSignatures);

        if (
            MerkleProof.multiProofVerify(proof, proofFlags, root, leaves) ==
            false
        ) {
            revert Errors.VerifyFailed();
        }
    }

    function _validateSignature(
        // IMessageSpaceStation.paramsLaunch calldata params,
        bytes32 encodedParams,
        bytes[] calldata launchParamsSignatures
    ) internal pure {
        // bytes32 data = abi.encode(params).hash();

        address[] memory validatorArray = new address[](
            launchParamsSignatures.length
        );
        for (uint256 i = 0; i < launchParamsSignatures.length; i++) {
            validatorArray[i] = address(
                uint160(
                    encodedParams.toEthSignedMessageHash().recover(
                        launchParamsSignatures[i]
                    )
                )
            );
        }
    }
}
