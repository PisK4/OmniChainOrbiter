// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IMessageVerificationSystem} from "./interface/IMessageVerificationSystem.sol";

contract MessageVerificationSystem is IMessageVerificationSystem, Ownable {
    constructor(bytes32 _root) Ownable(msg.sender) {}

    function verifyProofs(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) external pure override returns (bool) {
        return MerkleProof.multiProofVerify(proof, proofFlags, root, leaves);
    }
}
