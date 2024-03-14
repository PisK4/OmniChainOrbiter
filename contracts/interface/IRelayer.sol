// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

library RelayerStorageLib {
    function toStorage(
        mapping(bytes32 => IRelayerStorage.SignedMessageStruct) storage self,
        IRelayerStorage.SignedMessageStruct calldata signedMessage
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

interface IRelayerStorage {
    struct SignedMessageStruct {
        uint16 srcChainId;
        uint24[] nonceLaunch;
        bytes32 srcTxHash;
        bytes32 destTxHash;
        IMessageStruct.launchMultiMsgParams params;
    }
}

interface IRelayer {
    event LaunchMessageVerified(
        IRelayerStorage.SignedMessageStruct[] indexed signedMessage
    );

    function VerifyLaunchMessage(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        IRelayerStorage.SignedMessageStruct[] calldata signedMessage,
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
