// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IMessageSpaceStation} from "./interface/IMessageSpaceStation.sol";
import {IMessagePaymentSystem} from "./interface/IMessagePaymentSystem.sol";
import {IDefaultLandingHandler} from "./interface/IDefaultLandingHandler.sol";
import {IOrbiterMessageEmitter} from "./interface/IOrbiterMessageEmitter.sol";

import {MessageMonitor, MessageMonitorLib} from "./MessageMonitor.sol";
import {MessageTypeLib} from "./library/MessageTypeLib.sol";
import {Utils} from "./library/Utils.sol";
import {Errors} from "./library/Errors.sol";

/// the MessageSpaceStation is a contract that user can send cross-chain message to orther chain
/// Launch is the function that user or DApps send cross-chain message to orther chain
/// Landing is the function that trusted sequencer send cross-chain message to the Station
contract MessageSpaceStation is IMessageSpaceStation, MessageMonitor, Ownable {
    // using MessageMonitorLib for mapping(uint64 => mapping(address => uint24));
    using MessageMonitorLib for mapping(bytes32 => uint24);
    using MessageMonitorLib for uint256;
    using MessageMonitorLib for bytes;
    using MessageMonitorLib for uint24;
    using MessageTypeLib for bytes;
    using Utils for bytes;

    uint64 immutable MINIMAL_ARRIVAL_TIME = 3 minutes;
    uint64 immutable MAXIMAL_ARRIVAL_TIME = 30 days;
    uint64 immutable UNIVERSE_CHAIN_ID = type(uint64).max - 1;

    /// @dev trusted sequencer, we will execute the message from this address
    mapping(address => bool) public trustedSequencer;
    /// @dev handle default landing mode contract address
    IDefaultLandingHandler public defaultLandingHandler;
    /// @dev protocol fee payment system address
    IMessagePaymentSystem public paymentSystem;

    /// @dev engine status 0x01 is stop, 0x02 is start
    uint8 public isPause;
    /// @dev reentrancy guard
    uint8 private _isLanding = MessageMonitorLib.LANDING_PAD_FREE;

    bytes32 public mptRoots;

    receive() external payable {}

    constructor(
        address trustedSequencerAddr,
        address paymentSystemAddr
    ) payable Ownable(msg.sender) {
        configTrustedSequencer(trustedSequencerAddr, true);
        paymentSystem = IMessagePaymentSystem(paymentSystemAddr);
    }

    /// @notice if engine is stop, all message which pass to the Station will be revert
    /// @dev owner should call this function to stop the engine when the Station is under attack
    modifier launchEngineCheck(
        uint64 earlistArrivalTime,
        uint64 latestArrivalTime,
        uint256 protocolFee
    ) {
        if (isPause == MessageMonitorLib.ENGINE_STOP) {
            revert Errors.StationPaused();
        }

        if (msg.value < protocolFee) {
            revert Errors.ValueNotMatched();
        }

        if (
            (earlistArrivalTime < block.timestamp + MINIMAL_ARRIVAL_TIME) ||
            (latestArrivalTime > block.timestamp + MAXIMAL_ARRIVAL_TIME) ||
            latestArrivalTime < earlistArrivalTime
        ) {
            revert Errors.ArrivalTimeNotMakeSense();
        }
        _;
    }

    modifier landinglaunchEngineCheck() {
        if (isPause == MessageMonitorLib.ENGINE_STOP) {
            revert Errors.StationPaused();
        }
        if (_isLanding == MessageMonitorLib.LANDING_PAD_OCCUPIED) {
            revert Errors.LandingPadOccupied();
        }
        _isLanding = MessageMonitorLib.LANDING_PAD_OCCUPIED;
        _;
        _isLanding = MessageMonitorLib.LANDING_PAD_FREE;
    }

    modifier cargoInspection(
        uint64 aggregatedEarlistArrivalTime,
        uint64 aggregatedLatestArrivalTime
    ) {
        if (trustedSequencer[msg.sender] != true) {
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
    /// @dev the arguments of the function is packed in the launchMultiMsgParams struct
    ///      message won't be sent if the message is not valid or Protocol fee is not matched
    /// @param params the cross-chain needed params struct
    /// @return messageId the message id of the message
    function Launch(
        launchMultiMsgParams calldata params
    )
        external
        payable
        override
        launchEngineCheck(
            params.earlistArrivalTime,
            params.latestArrivalTime,
            FetchProtocolFee(params)
        )
        returns (bytes32[] memory messageId)
    {
        // if (msg.value < FetchProtocolFee(params)) {
        //     revert Errors.ValueNotMatched();
        // }

        if (params.message.length == 0) {
            revert Errors.InvalidMessage();
        }

        if (params.destChainld.length == params.message.length) {
            messageId = _LaunchOne2One(params);
        } else if (
            (params.destChainld.length > 1) && (params.message.length == 1)
        ) {
            messageId = _LaunchOne2Many(params);
        } else if (
            (params.destChainld.length == 1) && (params.message.length > 1)
        ) {
            messageId = _LaunchMany2One(params);
        } else if (params.destChainld.length == 0) {
            messageId = _Lanch2Universe(params);
        } else {
            revert Errors.InvalidMessage();
        }

        if (messageId.length != params.message.length) {
            revert Errors.InvalidMessage();
        }

        emit SuccessfulLaunch(messageId, params);
    }

    function Launch(
        launchSingleMsgParams calldata params
    )
        external
        payable
        override
        launchEngineCheck(
            params.earlistArrivalTime,
            params.latestArrivalTime,
            FetchProtocolFee(params)
        )
        returns (bytes32 messageId)
    {
        // if (msg.value < FetchProtocolFee(params)) {
        //     revert Errors.ValueNotMatched();
        // }

        messageId = nonceLaunch.handling(
            block.chainid,
            params.destChainld,
            params.sender,
            address(this)
        );

        emit SuccessfulLaunchSingle(messageId, params);
    }

    /// @notice batch landing message to the Station
    function Landing(
        bytes32 mptRoot,
        uint64 aggregatedEarlistArrivalTime,
        uint64 aggregatedLatestArrivalTime,
        paramsBatchLanding[] calldata params
    )
        external
        override
        landinglaunchEngineCheck
        cargoInspection(
            aggregatedEarlistArrivalTime,
            aggregatedLatestArrivalTime
        )
    {
        mptRoots = mptRoot;

        for (uint256 i = 0; i < params.length; i++) {
            emit SuccessfulBatchLanding(params[i].messgeId, params[i]);
        }
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
        landinglaunchEngineCheck
        cargoInspection(
            aggregatedEarlistArrivalTime,
            aggregatedLatestArrivalTime
        )
    {
        mptRoots = mptRoot;

        for (uint256 i = 0; i < params.length; i++) {
            if (params[i].value < msg.value) {
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
            if (messageType == MessageTypeLib.ARBITRARY_ACTIVATE) {
                params[i].message.activateArbitrarySig();
            } else if (messageType == MessageTypeLib.MESSAGE_POST) {
                // TODO: handle mail message
            } else {
                defaultLandingHandler.handleLandingParams(params[i]);
            }
            emit SuccessfulLanding(params[i].messgeId, params[i]);
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
    function FetchProtocolFee(
        launchMultiMsgParams calldata params
    ) public view override returns (uint256) {
        return paymentSystem.fetchProtocolFee_(params);
    }

    function FetchProtocolFee(
        launchSingleMsgParams calldata params
    ) public view override returns (uint256) {
        return paymentSystem.fetchProtocolFee_(params);
    }

    function FetchProtocolFee(
        IOrbiterMessageEmitter.activateRawMsg calldata params
    ) public view override returns (uint256) {
        return paymentSystem.fetchProtocolFee_(params);
    }

    function configTrustedSequencer(
        address trustedSequencerAddr,
        bool state
    ) public override onlyOwner {
        trustedSequencer[trustedSequencerAddr] = state;
    }

    /// @notice each message will be sent to corresponding chain
    /// @dev Explain to a developer any extra details
    function _LaunchOne2One(
        launchMultiMsgParams calldata params
    ) private returns (bytes32[] memory messageId) {
        messageId = _fetchMessageIdThenUpdateNonce(
            params,
            params.message.length
        );
    }

    /// @notice same message will be sent to multiple chains
    /// @dev Explain to a developer any extra details
    function _LaunchOne2Many(
        launchMultiMsgParams calldata params
    ) private returns (bytes32[] memory) {
        bytes32[] memory messageId = new bytes32[](params.destChainld.length);
        return
            messageId = _fetchMessageIdThenUpdateNonce(
                params,
                params.destChainld.length
            );
    }

    /// @notice many message will be sent to one chain
    /// @dev Explain to a developer any extra details
    function _LaunchMany2One(
        launchMultiMsgParams calldata params
    ) private returns (bytes32[] memory) {
        bytes32[] memory messageId = new bytes32[](params.message.length);
        return
            messageId = _fetchMessageIdThenUpdateNonce(
                params,
                params.destChainld[0],
                params.message.length
            );
    }

    /// @notice the message will be sent to all chains
    function _Lanch2Universe(
        launchMultiMsgParams calldata params
    ) private returns (bytes32[] memory) {
        bytes32[] memory messageId = new bytes32[](params.message.length);
        return
            messageId = _fetchMessageIdThenUpdateNonce(
                params,
                UNIVERSE_CHAIN_ID,
                params.message.length
            );
    }

    function _fetchMessageIdThenUpdateNonce(
        launchMultiMsgParams calldata params,
        uint256 loopMax
    ) private returns (bytes32[] memory) {
        bytes32[] memory messageId = new bytes32[](loopMax);
        for (uint256 i = 0; i < loopMax; i++) {
            messageId[i] = nonceLaunch.handling(
                block.chainid,
                params.destChainld[i],
                params.sender,
                address(this)
            );
        }
        return messageId;
    }

    function _fetchMessageIdThenUpdateNonce(
        launchMultiMsgParams calldata params,
        uint64 chainId,
        uint256 loopMax
    ) private returns (bytes32[] memory) {
        bytes32[] memory messageId = new bytes32[](loopMax);
        for (uint256 i = 0; i < loopMax; i++) {
            messageId[i] = nonceLaunch.fetchMessageId(
                block.chainid,
                chainId,
                params.sender,
                address(this)
            );
        }
        nonceLaunch.updates(chainId, params.sender, uint24(loopMax));
        return messageId;
    }
}
