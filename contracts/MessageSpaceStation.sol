// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMessageSpaceStation} from "./interface/IMessageSpaceStation.sol";
import {IMessagePaymentSystem} from "./interface/IMessagePaymentSystem.sol";
import {IDefaultLandingHandler} from "./interface/IDefaultLandingHandler.sol";
import {Utils} from "./library/Utils.sol";
import {Errors} from "./library/Errors.sol";
import {MessageMonitor, MessageMonitorLib} from "./MessageMonitor.sol";

/// the MessageSpaceStation is a contract that user can send cross-chain message to orther chain
/// Launch is the function that user or DApps send cross-chain message to orther chain
/// Landing is the function that trusted sequencer send cross-chain message to the Station
contract MessageSpaceStation is IMessageSpaceStation, MessageMonitor, Ownable {
    using MessageMonitorLib for mapping(uint64 => mapping(address => uint24));
    using MessageMonitorLib for bytes;
    using MessageMonitorLib for uint24;
    using MessageHashUtils for bytes32;
    using Utils for bytes;
    using ECDSA for bytes32;

    uint24 constant MINIMAL_ARRIVAL_TIME = 3 minutes;
    uint24 constant MAXIMAL_ARRIVAL_TIME = 30 days;

    /// @dev trusted sequencer, we will execute the message from this address
    address public trustedSequencer;
    /// @dev engine status 0x01 is stop, 0x02 is start
    uint8 public isPause;
    /// @dev handle default landing mode contract address
    IDefaultLandingHandler public defaultLandingHandler;
    /// @dev protocol fee payment system address
    IMessagePaymentSystem public paymentSystem;

    mapping(bytes32 => bytes32) public mptRoots;

    receive() external payable {}

    constructor(
        address _trustedSequencer,
        address _paymentSystemAddress
    ) payable Ownable(msg.sender) {
        trustedSequencer = _trustedSequencer;
        paymentSystem = IMessagePaymentSystem(_paymentSystemAddress);
    }

    /// @notice if engine is stop, all message which pass to the Station will be revert
    /// @dev owner should call this function to stop the engine when the Station is under attack
    modifier engineCheck() {
        if (isPause == MessageMonitorLib.ENGINE_STOP) {
            revert Errors.StationPaused();
        }
        _;
    }

    modifier cargoInspection(
        uint64 aggregatedEarlistArrivalTime,
        uint64 aggregatedLatestArrivalTime
    ) {
        if (msg.sender != trustedSequencer) {
            revert Errors.AccessDenied();
        }

        if (
            aggregatedEarlistArrivalTime > block.timestamp ||
            aggregatedLatestArrivalTime < block.timestamp
        ) {
            revert Errors.TimeNotReached();
        }
        _;
    }

    /// @notice LaunchPad is the function that user or DApps send cross-chain message to orther chain
    ///         Once the message is sent, the Relay will validate the message and send it to the target chain
    /// @dev the arguments of the function is packed in the paramsLaunch struct
    ///      message won't be sent if the message is not valid or Protocol fee is not matched
    /// @param params the cross-chain needed params struct
    /// @return messageId the message id of the message
    function Launch(
        paramsLaunch calldata params
    ) external payable override engineCheck returns (bytes32 messageId) {
        if (msg.value != FetchProtocalFee(params)) {
            revert Errors.ValueNotMatched();
        }

        if (
            (params.earlistArrivalTime <
                block.timestamp + MINIMAL_ARRIVAL_TIME) ||
            (params.latestArrivalTime >
                block.timestamp + MAXIMAL_ARRIVAL_TIME) ||
            params.latestArrivalTime < params.earlistArrivalTime
        ) {
            revert Errors.ArrivalTimeNotMakeSense();
        }

        messageId = nonceLanding[params.destChainld][params.sender]
            .fetchMessageId(
                block.chainid,
                params.destChainld,
                params.sender,
                params.relayer
            );

        nonceLaunch.update(params.destChainld, params.sender);

        emit SuccessfulLaunch(messageId, params);
    }

    /// @dev trusted sequencer will call this function to send cross-chain message to the Station
    /// @param mptRoot the merkle patricia tree root of all message
    /// @param aggregatedEarlistArrivalTime the earlist arrival time of all message
    /// @param aggregatedLatestArrivalTime the latest arrival time of all message
    /// @param params the cross-chain needed params struct
    function Landing(
        bytes32 mptRoot,
        uint64 aggregatedEarlistArrivalTime,
        uint64 aggregatedLatestArrivalTime,
        paramsLanding[] calldata params
    )
        external
        payable
        override
        engineCheck
        cargoInspection(
            aggregatedEarlistArrivalTime,
            aggregatedLatestArrivalTime
        )
    {
        bytes32 mptRootKeyHash = abi.encode(params).hash();
        if (mptRoots[mptRootKeyHash] != bytes32(0)) {
            revert Errors.DuplicatedValue();
        }
        mptRoots[mptRootKeyHash] = mptRoot;

        for (uint256 i = 0; i < params.length; i++) {
            if (params[i].value != msg.value) {
                revert Errors.ValueNotMatched();
            }
            if (
                nonceLanding.compare(
                    params[i].srcChainld,
                    params[i].sender,
                    params[i].nonceLandingCurrent
                ) != true
            ) {
                revert Errors.NonceNotMatched();
            }
            nonceLanding.update(uint64(block.chainid), params[i].sender);

            bytes1 messageType = params[i].message.fetchMessageType();
            if (messageType == MessageMonitorLib.AUTO_PILOT) {
                params[i].message.excuteSignature();
            } else if (messageType == MessageMonitorLib.MESSAGE_POST) {
                // TODO: handle mail message
            } else {
                defaultLandingHandler.handleLandingParams(params[i]);
            }
            emit SuccessfulLanding(params[i].messgeId, params[i]);
        }
    }

    function Landing(
        bytes32 mptRoot,
        uint64 aggregatedEarlistArrivalTime,
        uint64 aggregatedLatestArrivalTime,
        paramsBatchLanding[] calldata params
    )
        external
        override
        engineCheck
        cargoInspection(
            aggregatedEarlistArrivalTime,
            aggregatedLatestArrivalTime
        )
    {
        bytes32 mptRootKeyHash = abi.encode(params).hash();
        if (mptRoots[mptRootKeyHash] != bytes32(0)) {
            revert Errors.DuplicatedValue();
        }
        mptRoots[mptRootKeyHash] = mptRoot;

        for (uint256 i = 0; i < params.length; i++) {
            emit SuccessfulBatchLanding(params[i].messgeId, params[i]);
        }
    }

    /// @dev Only owner can call this function to stop or restart the engine
    /// @param _isPause true is stop, false is start
    function Pause(bool _isPause) external override onlyOwner {
        if (_isPause) {
            isPause = MessageMonitorLib.ENGINE_STOP;
        } else {
            isPause = MessageMonitorLib.ENGINE_START;
        }
        emit EngineStatusRefreshing(_isPause);
    }

    function Withdarw(uint256 amount) external override {
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
        }
    }

    function SetPaymentSystem(
        address paymentSystemAddress
    ) external override onlyOwner {
        if (paymentSystemAddress == address(0)) {
            revert Errors.InvalidAddress();
        }
        paymentSystem = IMessagePaymentSystem(paymentSystemAddress);
        emit PaymentSystemChanging(paymentSystemAddress);
    }

    /// @dev feel free to call this function before pass message to the Station,
    ///      this method will return the protocol fee that the message need to pay, longer message will pay more
    /// @param params the cross-chain needed params struct
    /// @return protocol fee, the unit is wei
    function FetchProtocalFee(
        paramsLaunch calldata params
    ) public view override returns (uint256) {
        return paymentSystem.fetchProtocalFee_(params);
    }
}
