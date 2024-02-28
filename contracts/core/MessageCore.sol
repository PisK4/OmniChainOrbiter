// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "../interface/IMessageSpaceStation.sol";
import {IMessagePaymentSystem} from "../interface/IMessagePaymentSystem.sol";
import {IDefaultLandingHandler} from "../interface/IDefaultLandingHandler.sol";
import {IMessageStruct} from "../interface/IMessageStruct.sol";
import {IMessageEvent} from "../interface/IMessageEvent.sol";
import {IMessageChannel} from "../interface/IMessageChannel.sol";

import {MessageMonitor, MessageMonitorLib} from "./MessageMonitor.sol";
import {MessageTypeLib} from "../library/MessageTypeLib.sol";
import {L2SupportLib} from "../library/L2SupportLib.sol";
import {Utils} from "../library/Utils.sol";
import {Errors} from "../library/Errors.sol";

/// the MessageSpaceStation is a contract that user can send cross-chain message to orther chain
/// Launch is the function that user or DApps send cross-chain message to orther chain
/// Landing is the function that trusted sequencer send cross-chain message to the Station
abstract contract MessageCore is
    IMessageSpaceStation,
    IMessageEvent,
    IMessageChannel,
    MessageMonitor
{
    using MessageMonitorLib for mapping(bytes32 => uint24);
    using MessageMonitorLib for uint256;
    using MessageMonitorLib for bytes;
    using MessageMonitorLib for uint24;
    using MessageTypeLib for bytes;
    using Utils for bytes;

    uint16 immutable UNIVERSE_CHAIN_ID = L2SupportLib.UNIVERSE_CHAIN_ID;

    /// @dev engine status 0x01 is stop, 0x02 is start
    uint8 public override isPaused;

    /// @dev reentrancy guard
    uint8 private _isLanding = MessageMonitorLib.LANDING_PAD_FREE;

    /// @dev handle default landing mode contract address
    IDefaultLandingHandler public defaultLandingHandler;

    /// @dev protocol fee payment system address
    IMessagePaymentSystem public paymentSystem;

    /// @dev trusted sequencer, we will execute the message from this address
    mapping(address => bool) public override TrustedSequencer;

    bytes32 public override mptRoot;

    receive() external payable {}

    modifier onlyManager() {
        if (msg.sender != Manager()) {
            revert Errors.AccessDenied();
        }
        _;
    }

    /// @notice if engine is stop, all message which pass to the Station will be revert
    /// @dev owner should call this function to stop the engine when the Station is under attack
    modifier launchEngineCheck(
        uint64 earlistArrivalTime,
        uint64 latestArrivalTime,
        uint256 protocolFee
    ) {
        if (isPaused == MessageMonitorLib.ENGINE_STOP) {
            revert Errors.StationPaused();
        }

        if (msg.value < protocolFee) {
            revert Errors.ValueNotMatched();
        }

        _checkArrivalTime(earlistArrivalTime, latestArrivalTime);
        _;
    }

    modifier landinglaunchEngineCheck() {
        if (isPaused == MessageMonitorLib.ENGINE_STOP) {
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
        if (TrustedSequencer[msg.sender] != true) {
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

    function Launch(
        launchMultiMsgParams calldata params
    )
        external
        payable
        override
        launchEngineCheck(
            params.earlistArrivalTime,
            params.latestArrivalTime,
            EstimateFee(params)
        )
        returns (bytes32[] memory messageId)
    {
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
            EstimateFee(params)
        )
        returns (bytes32 messageId)
    {
        messageId = nonceLaunch.handling(
            ChainId(),
            params.destChainld,
            params.sender,
            address(this)
        );

        emit SuccessfulLaunchSingle(messageId, params);
    }

    /// @notice batch landing message to the Station
    function Landing(
        bytes32 mptRootNew,
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
        mptRoot = mptRootNew;

        for (uint256 i = 0; i < params.length; i++) {
            emit SuccessfulBatchLanding(params[i].messgeId, params[i]);
        }
    }

    function Landing(
        bytes32 mptRootNew,
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
        mptRoot = mptRootNew;

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
            nonceLanding.update(ChainId(), params[i].sender);
            _handleInteractiveMessage(params[i]);
            emit SuccessfulLanding(params[i].messgeId, params[i]);
        }
    }

    function SimulateLanding(
        paramsLanding[] calldata params
    ) external override {
        bool[] memory success = new bool[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            success[i] = _handleInteractiveMessage(params[i]);
        }
        revert Errors.SimulateFailed(success);
    }

    function _handleInteractiveMessage(
        paramsLanding calldata params
    ) internal returns (bool success) {
        bytes1 messageType = params.message.fetchMessageType();
        if (messageType == MessageTypeLib.ARBITRARY_ACTIVATE) {
            (success, ) = params.message.activateArbitrarySig();
            // TODO: handle failed message
            if (!success) {
                //
            }
        } else if (messageType == MessageTypeLib.MESSAGE_POST) {
            // TODO: handle mail message
        } else {
            defaultLandingHandler.handleLandingParams(params);
        }
    }

    function PauseEngine(bool stop) external override onlyManager {
        if (stop) {
            isPaused = MessageMonitorLib.ENGINE_STOP;
        } else {
            isPaused = MessageMonitorLib.ENGINE_START;
        }
        emit EngineStatusRefreshing(stop);
    }

    function Withdarw(uint256 amount) external override {
        (bool sent, ) = payable(Manager()).call{value: amount}("");
        if (!sent) {
            revert Errors.WithdrawError();
        }
    }

    function SetPaymentSystem(
        address paymentSystemAddress
    ) external override onlyManager {
        if (paymentSystemAddress == address(0)) {
            revert Errors.InvalidAddress();
        }
        paymentSystem = IMessagePaymentSystem(paymentSystemAddress);
        emit PaymentSystemChanging(paymentSystemAddress);
    }

    function EstimateFee(
        launchMultiMsgParams calldata params
    ) public view override returns (uint256) {
        return paymentSystem.EstimateFee_(params);
    }

    function EstimateFee(
        launchSingleMsgParams calldata params
    ) public view override returns (uint256) {
        return paymentSystem.EstimateFee_(params);
    }

    function ConfigTrustedSequencer(
        address trustedSequencerAddr,
        bool state
    ) public override onlyManager {
        TrustedSequencer[trustedSequencerAddr] = state;
    }

    function GetNonceLaunch(
        uint16 chainId,
        address sender
    ) external view override returns (uint24) {
        return nonceLaunch.fetchNonce(chainId, sender);
    }

    function GetNonceLanding(
        uint16 chainId,
        address sender
    ) external view override returns (uint24) {
        return nonceLanding.fetchNonce(chainId, sender);
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
                ChainId(),
                params.destChainld[i],
                params.sender,
                address(this)
            );
        }
        return messageId;
    }

    function _fetchMessageIdThenUpdateNonce(
        launchMultiMsgParams calldata params,
        uint16 chainId,
        uint256 loopMax
    ) private returns (bytes32[] memory) {
        bytes32[] memory messageId = new bytes32[](loopMax);
        for (uint256 i = 0; i < loopMax; i++) {
            messageId[i] = nonceLaunch.fetchMessageId(
                ChainId(),
                chainId,
                params.sender,
                address(this)
            );
        }
        nonceLaunch.updates(chainId, params.sender, uint24(loopMax));
        return messageId;
    }

    function _checkArrivalTime(
        uint64 earlistArrivalTime,
        uint64 latestArrivalTime
    ) internal view virtual {
        (earlistArrivalTime, latestArrivalTime);
        // revert Errors.NotImplement();
    }

    function ChainId() public pure virtual override returns (uint16) {
        // revert Errors.NotImplement();
    }

    function Manager() public view virtual override returns (address) {
        // revert Errors.NotImplement();
    }
}
