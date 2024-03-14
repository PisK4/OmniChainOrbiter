// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {IRelayer, IRelayerStorage, RelayerStorageLib} from "./interface/IRelayer.sol";
import {IMessageStruct} from "./interface/IMessageStruct.sol";
import {Utils} from "./library/Utils.sol";
import {Errors} from "./library/Errors.sol";

contract Relayer is IRelayer, IRelayerStorage, Ownable {
    using MessageHashUtils for bytes32;
    using RelayerStorageLib for mapping(bytes32 => IRelayerStorage.SignedMessageStruct);
    using Utils for bytes;
    using ECDSA for bytes32;

    uint8 public override SignaturesThreshold;
    uint8 public override ValidatorCount;

    mapping(bytes32 => SignedMessageStruct) public MessageSaved;

    mapping(address => bool) public override RegistedValidator;

    constructor() payable Ownable(msg.sender) {}

    function VerifyLaunchMessage(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        IRelayerStorage.SignedMessageStruct[] calldata signedMessage,
        bytes[] calldata launchParamsSignatures
    ) external override {
        _validateSignature(
            abi.encode(signedMessage).hash(),
            launchParamsSignatures
        );
        bytes32[] memory leaves = new bytes32[](signedMessage.length);
        for (uint256 i = 0; i < signedMessage.length; i++) {
            leaves[i] = abi.encode(signedMessage[i]).hash();
            if (MessageSaved.toStorage(signedMessage[i]) == false) {
                revert Errors.DuplicatedValue();
            }
        }

        if (
            MerkleProof.multiProofVerify(proof, proofFlags, root, leaves) ==
            false
        ) {
            revert Errors.VerifyFailed();
        }
        emit LaunchMessageVerified(signedMessage);
    }

    function SetupValidator(
        address[] calldata validators,
        bool[] calldata statues
    ) external override onlyOwner {
        if (validators.length != statues.length) {
            revert Errors.SetupError();
        }
        for (uint256 i = 0; i < validators.length; i++) {
            RegistedValidator[validators[i]] = statues[i];
            if (statues[i] == true) {
                ValidatorCount++;
            } else {
                ValidatorCount--;
            }
        }
        SignaturesThreshold = (ValidatorCount + 2) / 3;
    }

    function _validateSignature(
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
        // TODO: check if the validators are registered
    }
}
