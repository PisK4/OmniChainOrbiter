// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMessageSpaceStation} from "./interface/IMessageSpaceStation.sol";
import {Utils} from "./library/Utils.sol";
import {Errors} from "./library/Errors.sol";
import {MessageMonitor, MessageMonitorLib} from "./MessageMonitor.sol";

import "hardhat/console.sol";

contract MessageSpaceStation is IMessageSpaceStation, MessageMonitor, Ownable {
    using MessageMonitorLib for mapping(uint64 => mapping(address => uint24));
    using MessageMonitorLib for bytes;
    using Utils for bytes;
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @dev trusted sequencer, we will execute the message from this address
    address public trustedSequencer;
    /// @dev engine status 0x01 is stop, 0x02 is start
    uint8 public isPause;
    uint8 constant validatorSignaturesLowerLimit = 2;

    receive() external payable {}

    constructor(address _trustedSequencer) payable Ownable(msg.sender) {
        trustedSequencer = _trustedSequencer;
    }

    modifier engineCheck() {
        if (isPause == MessageMonitorLib.ENGINE_STOP) {
            revert Errors.isPause();
        }
        _;
    }

    function Launch(
        paramsLaunch calldata params
    ) external payable override engineCheck returns (bytes32 messageId) {
        messageId = abi
            .encode(
                params.destChainld,
                params.sender,
                address(this),
                nonceLanding[params.destChainld][params.sender]
            )
            .hash();

        nonceLaunch.update(params.destChainld, params.sender);
    }

    function Landing(
        bytes[] calldata validatorSignatures,
        paramsLanding calldata params
    ) external payable override engineCheck {
        if (msg.sender != trustedSequencer) {
            revert Errors.NotTrustedSequencer();
        }
        (validatorSignatures);
        // _validateSignature(params, validatorSignatures);
        if (
            nonceLanding.compare(
                params.scrChainld,
                params.sender,
                params.nonceLaunch
            ) != true
        ) {
            revert Errors.NonceNotMatched();
        }
        nonceLanding.update(params.scrChainld, params.sender);

        if (params.value != msg.value) {
            revert Errors.ValueNotMatched();
        }

        if (params.message.fetchMessageType() == MessageMonitorLib.EXCUTE) {
            params.message.excuteSignature();
        }
    }

    function pause(bool _isPause) external override onlyOwner {
        if (_isPause) {
            isPause = MessageMonitorLib.ENGINE_STOP;
        } else {
            isPause = MessageMonitorLib.ENGINE_START;
        }
    }

    function withdarw(uint256 amount) external override {
        (bool sent, ) = payable(owner()).call{value: amount}("");
        if (!sent) {
            revert Errors.WithdrawError();
        }
    }

    function _validateSignature(
        paramsLanding calldata params,
        bytes[] calldata responseMakerSignatures
    ) internal pure {
        bytes32 data = abi.encode(params).hash();

        address[] memory validatorArray = new address[](
            responseMakerSignatures.length
        );
        for (uint256 i = 0; i < responseMakerSignatures.length; i++) {
            validatorArray[i] = address(
                uint160(
                    data.toEthSignedMessageHash().recover(
                        responseMakerSignatures[i]
                    )
                )
            );

            console.log("validatorArray[i]: %s", validatorArray[i]);
        }
    }
}
