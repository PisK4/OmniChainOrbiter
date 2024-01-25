// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMessageSpaceStation} from "./interface/IMessageSpaceStation.sol";
import {Utils} from "./library/Utils.sol";
import {Errors} from "./library/Errors.sol";
import {MessageMonitor, MessageMonitorLib} from "./MessageMonitor.sol";

contract MessageSpaceStation is IMessageSpaceStation, MessageMonitor {
    using MessageMonitorLib for mapping(uint64 => mapping(address => uint24));
    using MessageMonitorLib for bytes;
    using Utils for bytes;
    /// @dev trusted sequencer, we will execute the message from this address
    address public trustedSequencer;

    receive() external payable {}

    constructor(address _trustedSequencer) payable {
        trustedSequencer = _trustedSequencer;
    }

    function Launch(
        launchParams calldata params
    ) external payable override returns (bytes32 messageId) {
        messageId = abi
            .encode(
                params.destChainld,
                params.sender,
                address(this),
                landNonce[params.destChainld][params.sender]
            )
            .hash();

        launchNonce.update(params.destChainld, params.sender);
    }

    function Land(
        bytes[] calldata validatorSignatures,
        landParams calldata params
    ) external override {
        if (msg.sender != trustedSequencer) {
            revert Errors.NotTrustedSequencer();
        }
        (validatorSignatures);
        if (
            landNonce.compare(
                params.scrChainld,
                params.sender,
                params.launchNonce
            ) != true
        ) {
            revert Errors.NonceNotMatched();
        }
        landNonce.update(params.scrChainld, params.sender);

        if (params.message.getType() == LandingMessageType.EXCUTE) {
            params.message.excuteSignature();
        }
    }
}
