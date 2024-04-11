// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "../interface/IMessageSpaceStation.sol";
import {IMessagePaymentSystem} from "../interface/IMessagePaymentSystem.sol";
import {IExpertLandingHandler} from "../interface/IExpertLandingHandler.sol";
import {MessageMonitor, MessageMonitorLib} from "./MessageMonitor.sol";
import {MessageTypeLib} from "../library/MessageTypeLib.sol";
import {L2SupportLib} from "../library/L2SupportLib.sol";
import {Utils} from "../library/Utils.sol";
import {Errors} from "../library/Errors.sol";

/// the MessageSpaceStation is a contract that user can send cross-chain message to orther chain
/// Launch is the function that user or DApps send cross-chain message to orther chain
/// Landing is the function that trusted relayer send cross-chain message to the Station
abstract contract MessageCore is IMessageSpaceStation, MessageMonitor {
    using MessageMonitorLib for mapping(bytes32 => uint24);
    using MessageMonitorLib for uint256;
    using MessageMonitorLib for bytes;
    using MessageMonitorLib for uint24;
    using MessageTypeLib for bytes;
    using Utils for bytes;

    uint16 constant UNIVERSE_CHAIN_ID = L2SupportLib.UNIVERSE_CHAIN_ID;

    /// @dev engine status 0x01 is stop, 0x02 is start
    uint8 internal _isPaused;

    /// @dev reentrancy guard
    uint8 internal _isLanding;

    /// @dev handle default landing mode contract address
    IExpertLandingHandler public ExpertLandingHandler;

    /// @dev protocol fee payment system address
    IMessagePaymentSystem public paymentSystem;

    /// @dev trusted relayer, we will execute the message from this address
    mapping(address => bool) public override TrustedRelayer;

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
        uint256 value,
        uint256 protocolFee
    ) {
        if (isPaused() != MessageMonitorLib.ENGINE_START) {
            revert Errors.StationPaused();
        }

        if (msg.value < protocolFee + value) {
            revert Errors.ValueNotMatched();
        }

        _checkArrivalTime(earlistArrivalTimestamp, latestArrivalTimestamp);
        _;
    }

    modifier landingEngineCheck() {
        if (isPaused() != MessageMonitorLib.ENGINE_START) {
            revert Errors.StationPaused();
        }
        if (isLanding() != MessageMonitorLib.LANDING_PAD_FREE) {
            revert Errors.LandingPadOccupied();
        }
        _setLanding(MessageMonitorLib.LANDING_PAD_OCCUPIED);
        _;
        _setLanding(MessageMonitorLib.LANDING_PAD_FREE);
    }

    modifier cargoInspection(
        uint64 aggregatedEarlistArrivalTimestamp,
        uint64 aggregatedLatestArrivalTimestamp
    ) {
        if (!isTrustedRelayer(msg.sender)) {
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
            _sumValueArray(params.value),
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
            params.value,
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
        landingEngineCheck
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
        landingEngineCheck
        cargoInspection(
            aggregatedEarlistArrivalTimestamp,
            aggregatedLatestArrivalTimestamp
        )
    {
        (mptRootNew);
        for (uint256 i = 0; i < params.length; i++) {
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
            (success, ) = params.message.activateArbitrarySig(params.value);
            if (!success) {
                revert Errors.ExcuteError(params.messgeId);
            }
        } else {
            ExpertLandingHandler.handleLandingParams(params);
        }
    }

    function PauseEngine(bool stop) external override onlyManager {
        if (stop) {
            // isPaused = MessageMonitorLib.ENGINE_STOP;
            _setPaused(MessageMonitorLib.ENGINE_STOP);
        } else {
            // isPaused = MessageMonitorLib.ENGINE_START;
            _setPaused(MessageMonitorLib.ENGINE_START);
        }
        emit EngineStatusRefreshing(stop);
    }

    function Withdraw(uint256 amount) external override {
        (bool sent, ) = payable(Manager()).call{value: amount}("");
        if (!sent) {
            revert Errors.WithdrawError();
        }
        emit WithdrawRequest(amount);
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

    function ConfigTrustedRelayer(
        address trustedRelayerAddr,
        bool state
    ) public override onlyManager {
        TrustedRelayer[trustedRelayerAddr] = state;
        emit SequencerStatusChanging(trustedRelayerAddr, state);
    }

    function isTrustedRelayer(
        address addr
    ) public view override returns (bool) {
        return TrustedRelayer[addr];
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
        return _noncehandling(params, params.message.length);
    }

    /// @notice same message will be sent to multiple chains
    /// @dev Explain to a developer any extra details
    function _LaunchOne2Many(
        launchMultiMsgParams calldata params
    ) private returns (uint24[] memory) {
        return _noncehandling(params, params.destChainld.length);
    }

    /// @notice many message will be sent to one chain
    /// @dev Explain to a developer any extra details
    function _LaunchMany2One(
        launchMultiMsgParams calldata params
    ) private returns (uint24) {
        return
            _noncehandling(
                params,
                params.destChainld[0],
                params.message.length
            );
    }

    /// @notice the message will be sent to all chains
    function _Lanch2Universe(
        launchMultiMsgParams calldata params
    ) private returns (uint24) {
        return _noncehandling(params, UNIVERSE_CHAIN_ID, params.message.length);
    }

    function _noncehandling(
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

    function _noncehandling(
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

    function _sumValueArray(
        uint256[] calldata values
    ) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i < values.length; i++) {
            sum += values[i];
        }
    }

    function isPaused() public view override returns (uint8) {
        return _isPaused;
    }

    function _setPaused(uint8 state) internal {
        _isPaused = state;
    }

    function isLanding() public view returns (uint8) {
        return _isLanding;
    }

    function _setLanding(uint8 state) internal {
        _isLanding = state;
    }

    function ChainId() public pure virtual override returns (uint16) {
        // revert Errors.NotImplement();
    }

    function Manager() public view virtual override returns (address) {
        // revert Errors.NotImplement();
    }
}
