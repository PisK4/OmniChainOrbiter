// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

library RelayerStorageLib {
    function toStorage(
        mapping(bytes32 => IRelayerStorage.SignedMessageStruct) storage self,
        IRelayerStorage.SignedMessageStruct calldata signedMessage
    ) internal {
        self[
            keccak256(abi.encode(signedMessage.chainId, signedMessage.txHash))
        ] = signedMessage;
    }
}

interface IRelayerStorage {
    struct SignedMessageStruct {
        uint16 chainId;
        bytes32 messageId;
        bytes32 txHash;
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

    function SetupValidator(
        address[] calldata validators,
        bool[] calldata statues
    ) external;
}
