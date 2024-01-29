// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMessageSpaceStation} from "./interface/IMessageSpaceStation.sol";
import {IMessagePaymentSystem} from "./interface/IMessagePaymentSystem.sol";
import {Utils} from "./library/Utils.sol";
import {Errors} from "./library/Errors.sol";
import {MessageMonitor, MessageMonitorLib} from "./MessageMonitor.sol";

import "hardhat/console.sol";

contract MessageSpaceStation is IMessageSpaceStation, MessageMonitor, Ownable {
    using MessageMonitorLib for mapping(uint64 => mapping(address => uint24));
    using MessageMonitorLib for bytes;
    using MessageMonitorLib for uint24;
    using MessageHashUtils for bytes32;
    using Utils for bytes;
    using ECDSA for bytes32;

    /// @dev trusted sequencer, we will execute the message from this address
    address public trustedSequencer;
    /// @dev payment system address
    IMessagePaymentSystem public paymentSystem;
    /// @dev engine status 0x01 is stop, 0x02 is start
    uint8 public isPause;
    /// @dev number of trusted messageSingners limit of the message
    uint8 constant validatorSignaturesLowerLimit = 2;

    receive() external payable {}

    constructor(
        address _trustedSequencer,
        address _paymentSystemAddress
    ) payable Ownable(msg.sender) {
        trustedSequencer = _trustedSequencer;
        paymentSystem = IMessagePaymentSystem(_paymentSystemAddress);
    }

    modifier engineCheck() {
        if (isPause == MessageMonitorLib.ENGINE_STOP) {
            revert Errors.StationPaused();
        }
        _;
    }

    function Launch(
        MessageMonitorLib.paramsLaunch calldata params
    ) external payable override engineCheck returns (bytes32 messageId) {
        if (msg.value != fetchProtocalFee(params)) {
            revert Errors.ValueNotMatched();
        }
        messageId = nonceLanding[params.destChainld][params.sender]
            .fetchMessageId(params.destChainld, params.sender, params.relayer);

        nonceLaunch.update(params.destChainld, params.sender);

        emit SuccessfulLaunch(messageId, params);
    }

    function Landing(
        bytes[] calldata validatorSignatures,
        MessageMonitorLib.paramsLanding calldata params
    ) external payable override engineCheck {
        if (msg.sender != trustedSequencer) {
            revert Errors.AccessDenied();
        }
        (validatorSignatures);
        // _validateSignature(params, validatorSignatures);
        if (
            nonceLanding.compare(
                params.scrChainld,
                params.sender,
                params.nonceLandingCurrent
            ) != true
        ) {
            revert Errors.NonceNotMatched();
        }
        nonceLanding.update(uint64(block.chainid), params.sender);

        if (params.value != msg.value) {
            revert Errors.ValueNotMatched();
        }

        bytes1 messageType = params.message.fetchMessageType();
        if (messageType == MessageMonitorLib.EXCUTE) {
            params.message.excuteSignature();
        } else if (messageType == MessageMonitorLib.MAIL) {}

        emit SuccessfulLanding(params.messgeId, params);
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
        MessageMonitorLib.paramsLanding calldata params,
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
        }
    }

    function setPaymentSystem(
        address paymentSystemAddress
    ) external override onlyOwner {
        if (paymentSystemAddress == address(0)) {
            revert Errors.InvalidAddress();
        }
        paymentSystem = IMessagePaymentSystem(paymentSystemAddress);
    }

    function fetchProtocalFee(
        MessageMonitorLib.paramsLaunch calldata params
    ) public view override returns (uint256) {
        return paymentSystem.fetchProtocalFee(params);
    }
}
