// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

library RelayerStorageLib {
    function toStorage(
        mapping(bytes32 => IMessageStruct.SignedMessageStruct) storage self,
        IMessageStruct.SignedMessageStruct calldata signedMessage
    ) internal returns (bool messageNotSaved) {
        bytes32 key = keccak256(
            abi.encode(signedMessage.srcChainId, signedMessage.srcTxHash)
        );
        if (self[key].srcTxHash != bytes32(0)) {
            return false;
        }
        self[key] = signedMessage;
        return true;
    }
}

interface IRelayer {
    event LaunchMessageVerified(
        IMessageStruct.SignedMessageStruct[] indexed signedMessage
    );

    function VerifyLaunchMessage(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        IMessageStruct.SignedMessageStruct[] calldata signedMessage,
        bytes[] calldata launchParamsSignatures
    ) external;

    function RegistedValidator(address validator) external returns (bool);

    function SignaturesThreshold() external returns (uint8);

    function ValidatorCount() external returns (uint8);

    function SetupValidator(
        address[] calldata validators,
        bool[] calldata statues
    ) external;
}
