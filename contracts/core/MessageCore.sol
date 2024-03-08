// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "../interface/IMessageSpaceStation.sol";
import {IMessagePaymentSystem} from "../interface/IMessagePaymentSystem.sol";
import {IDefaultLandingHandler} from "../interface/IDefaultLandingHandler.sol";
import {MessageMonitor, MessageMonitorLib} from "./MessageMonitor.sol";
import {MessageTypeLib} from "../library/MessageTypeLib.sol";
import {L2SupportLib} from "../library/L2SupportLib.sol";
import {Utils} from "../library/Utils.sol";
import {Errors} from "../library/Errors.sol";

/// the MessageSpaceStation is a contract that user can send cross-chain message to orther chain
/// Launch is the function that user or DApps send cross-chain message to orther chain
/// Landing is the function that trusted sequencer send cross-chain message to the Station
abstract contract MessageCore is IMessageSpaceStation, MessageMonitor {
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

    // bytes32 public override mptRoot;

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
        uint64 earlistArrivalTimestamp,
        uint64 latestArrivalTimestamp,
        uint256 protocolFee
    ) {
        if (isPaused == MessageMonitorLib.ENGINE_STOP) {
            revert Errors.StationPaused();
        }

        if (msg.value < protocolFee) {
            revert Errors.ValueNotMatched();
        }

        _checkArrivalTime(earlistArrivalTimestamp, latestArrivalTimestamp);
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
        uint64 aggregatedEarlistArrivalTimestamp,
        uint64 aggregatedLatestArrivalTimestamp
    ) {
        if (TrustedSequencer[msg.sender] != true) {
            revert Errors.AccessDenied();
        }

        if (
            aggregatedEarlistArrivalTimestamp > block.timestamp ||
            aggregatedLatestArrivalTimestamp < block.timestamp
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
            params.earlistArrivalTimestamp,
            params.latestArrivalTimestamp,
            EstimateFee(params)
        )
    {
        if (params.message.length == 0) {
            revert Errors.InvalidMessage();
        }

        if (params.destChainld.length == params.message.length) {
            emit SuccessfulLaunchMessages(_LaunchOne2One(params), params);
        } else if (
            (params.destChainld.length > 1) && (params.message.length == 1)
        ) {
            emit SuccessfulLaunchMessages(_LaunchOne2Many(params), params);
        } else if (
            (params.destChainld.length == 1) && (params.message.length > 1)
        ) {
            emit SuccessfulLaunchMessages2(_LaunchMany2One(params), params);
        } else if (params.destChainld.length == 0) {
            emit SuccessfulLaunchMessages2(_Lanch2Universe(params), params);
        } else {
            revert Errors.InvalidMessage();
        }

        // emit SuccessfulLaunchMessages(bytes32(0), params);
    }

    function Launch(
        launchSingleMsgParams calldata params
    )
        external
        payable
        override
        launchEngineCheck(
            params.earlistArrivalTimestamp,
            params.latestArrivalTimestamp,
            EstimateFee(params)
        )
    {
        emit SuccessfulLaunchMessage(
            nonceLaunch.update(params.destChainld, params.sender),
            params
        );
    }

    /// @notice post the landing messageID to the chain
    function Landing(
        bytes32 mptRootNew,
        uint64 aggregatedEarlistArrivalTimestamp,
        uint64 aggregatedLatestArrivalTimestamp,
        PostingLanding[] calldata params
    )
        external
        override
        landinglaunchEngineCheck
        cargoInspection(
            aggregatedEarlistArrivalTimestamp,
            aggregatedLatestArrivalTimestamp
        )
    {
        (mptRootNew);

        for (uint256 i = 0; i < params.length; i++) {
            emit SuccessfulBatchLanding(params[i].messgeId, params[i]);
        }
    }

    /// @notice execute the landing message
    function Landing(
        bytes32 mptRootNew,
        uint64 aggregatedEarlistArrivalTimestamp,
        uint64 aggregatedLatestArrivalTimestamp,
        InteractionLanding[] calldata params
    )
        external
        payable
        override
        landinglaunchEngineCheck
        cargoInspection(
            aggregatedEarlistArrivalTimestamp,
            aggregatedLatestArrivalTimestamp
        )
    {
        (mptRootNew);

        for (uint256 i = 0; i < params.length; i++) {
            // if (params[i].value < msg.value) {
            //     revert Errors.ValueNotMatched();
            // }
            // if (
            //     nonceLanding.compare(
            //         params[i].srcChainld,
            //         params[i].sender,
            //         params[i].nonceLandingCurrent
            //     ) != true
            // ) {
            //     revert Errors.NonceNotMatched();
            // }
            // nonceLanding.update(ChainId(), params[i].sender);
            _handleInteractiveMessage(params[i]);
            emit SuccessfulLanding(params[i].messgeId, params[i]);
        }
    }

    function SimulateLanding(
        InteractionLanding[] calldata params
    ) external override {
        revert Errors.SimulateResult(EstimateExcuteGas(params));
    }

    function EstimateExcuteGas(
        InteractionLanding[] calldata params
    ) public override returns (bool[] memory) {
        bool[] memory result = new bool[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            result[i] = _handleInteractiveMessage(params[i]);
        }
        return result;
    }

    function _handleInteractiveMessage(
        InteractionLanding calldata params
    ) internal returns (bool success) {
        bytes1 messageType = params.message.fetchMsgMode();
        if (messageType == MessageTypeLib.ARBITRARY_ACTIVATE) {
            (success, ) = params.message.activateArbitrarySig();
            if (!success) {
                revert Errors.ExcuteError(params.messgeId);
            }
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
    ) private returns (uint24[] memory) {
        return _fetchMessageIdThenUpdateNonce(params, params.message.length);
    }

    /// @notice same message will be sent to multiple chains
    /// @dev Explain to a developer any extra details
    function _LaunchOne2Many(
        launchMultiMsgParams calldata params
    ) private returns (uint24[] memory) {
        return
            _fetchMessageIdThenUpdateNonce(params, params.destChainld.length);
    }

    /// @notice many message will be sent to one chain
    /// @dev Explain to a developer any extra details
    function _LaunchMany2One(
        launchMultiMsgParams calldata params
    ) private returns (uint24) {
        return
            _fetchMessageIdThenUpdateNonce(
                params,
                params.destChainld[0],
                params.message.length
            );
    }

    /// @notice the message will be sent to all chains
    function _Lanch2Universe(
        launchMultiMsgParams calldata params
    ) private returns (uint24) {
        return
            _fetchMessageIdThenUpdateNonce(
                params,
                UNIVERSE_CHAIN_ID,
                params.message.length
            );
    }

    function _fetchMessageIdThenUpdateNonce(
        launchMultiMsgParams calldata params,
        uint256 loopMax
    ) private returns (uint24[] memory) {
        uint24[] memory nonces = new uint24[](loopMax);
        for (uint256 i = 0; i < loopMax; i++) {
            nonces[i] = nonceLaunch.update(
                params.destChainld[i],
                params.sender
            );
        }
        return nonces;
    }

    function _fetchMessageIdThenUpdateNonce(
        launchMultiMsgParams calldata params,
        uint16 chainId,
        uint256 loopMax
    ) private returns (uint24) {
        return nonceLaunch.updates(chainId, params.sender, uint24(loopMax));
    }

    function _checkArrivalTime(
        uint64 earlistArrivalTimestamp,
        uint64 latestArrivalTimestamp
    ) internal view virtual {
        (earlistArrivalTimestamp, latestArrivalTimestamp);
        // revert Errors.NotImplement();
    }

    function ChainId() public pure virtual override returns (uint16) {
        // revert Errors.NotImplement();
    }

    function Manager() public view virtual override returns (address) {
        // revert Errors.NotImplement();
    }
}
