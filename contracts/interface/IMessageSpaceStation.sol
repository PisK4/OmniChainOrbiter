// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import {IMessageEmitter} from "./IMessageEmitter.sol";

interface IMessageSpaceStation {
    struct launchSingleMsgParams {
        uint64 earlistArrivalTime;
        uint64 latestArrivalTime;
        address relayer;
        address sender;
        uint16 destChainld;
        bytes aditionParams;
        bytes message;
    }

    struct launchMultiMsgParams {
        uint64 earlistArrivalTime;
        uint64 latestArrivalTime;
        address relayer;
        address sender;
        uint16[] destChainld;
        bytes[] aditionParams;
        bytes[] message;
    }

    struct paramsLanding {
        uint16 srcChainld;
        uint24 nonceLandingCurrent;
        address sender;
        uint256 value;
        bytes32 messgeId;
        bytes message;
    }

    struct paramsBatchLanding {
        uint16 srcChainld;
        address sender;
        bytes32 messgeId;
    }

    event SuccessfulLaunch(
        bytes32[] indexed messageId,
        launchMultiMsgParams params
    );
    event SuccessfulLaunchSingle(
        bytes32 indexed messageId,
        launchSingleMsgParams params
    );
    event SuccessfulLanding(bytes32 indexed messageId, paramsLanding params);
    event SuccessfulBatchLanding(
        bytes32 indexed messageId,
        paramsBatchLanding params
    );
    event EngineStatusRefreshing(bool isPause);
    event PaymentSystemChanging(address paymentSystemAddress);

    /// @notice LaunchPad is the function that user or DApps send cross-chain message to orther chain
    ///         Once the message is sent, the Relay will validate the message and send it to the target chain
    /// @dev the arguments of the function is packed in the launchMultiMsgParams struct
    ///      message won't be sent if the message is not valid or Protocol fee is not matched
    /// @param params the cross-chain needed params struct
    /// @return messageId the message id of the message
    function Launch(
        launchMultiMsgParams calldata params
    ) external payable returns (bytes32[] memory messageId);

    function Launch(
        launchSingleMsgParams calldata params
    ) external payable returns (bytes32 messageId);

    /// @notice batch landing message to the chain, execute the landing message
    /// @dev trusted sequencer will call this function to send cross-chain message to the Station
    /// @param mptRootNew the merkle patricia trie root of the message
    /// @param aggregatedEarlistArrivalTime the earlist arrival time of the message
    /// @param aggregatedLatestArrivalTime the latest arrival time of the message
    /// @param params the landing message params
    function Landing(
        bytes32 mptRootNew,
        uint64 aggregatedEarlistArrivalTime,
        uint64 aggregatedLatestArrivalTime,
        paramsLanding[] calldata params
    ) external payable;

    /// @notice batch landing message to the chain, only post the landing message to the chain
    /// @dev trusted sequencer will call this function to send cross-chain message to the Station
    /// @param mptRootNew the merkle patricia trie root of the message
    /// @param aggregatedEarlistArrivalTime the earlist arrival time of the message
    /// @param aggregatedLatestArrivalTime the latest arrival time of the message
    /// @param params the landing message params
    function Landing(
        bytes32 mptRootNew,
        uint64 aggregatedEarlistArrivalTime,
        uint64 aggregatedLatestArrivalTime,
        paramsBatchLanding[] calldata params
    ) external;

    /// @dev for sequencer to simulate the landing message, call this function before call Landing
    /// @param params the landing message params
    /// check the revert message "SimulateFailed" to get the result of the simulation
    /// for example, if the result is [true, false, true], it means the first and third message is valid, the second message is invalid
    function SimulateLanding(paramsLanding[] calldata params) external;

    /// @dev Only owner can call this function to stop or restart the engine
    /// @param stop true is stop, false is start
    function PauseEngine(bool stop) external;

    /// @notice return the status of the engine
    /// @return 0x01 is stop, 0x02 is start
    function isPaused() external view returns (uint8);

    function mptRoot() external view returns (bytes32);

    /// @dev withdraw the protocol fee from the contract, only owner can call this function
    /// @param amount the amount of the withdraw protocol fee
    function Withdarw(uint256 amount) external;

    /// @dev set the payment system address, only owner can call this function
    /// @param paymentSystemAddress the address of the payment system
    function SetPaymentSystem(address paymentSystemAddress) external;

    /// @dev feel free to call this function before pass message to the Station,
    ///      this method will return the protocol fee that the message need to pay, longer message will pay more
    /// @param params the cross-chain needed params struct
    /// @return protocol fee, the unit is wei
    function EstimateFee(
        launchMultiMsgParams calldata params
    ) external view returns (uint256);

    function EstimateFee(
        launchSingleMsgParams calldata params
    ) external view returns (uint256);

    function EstimateFee(
        IMessageEmitter.activateRawMsg calldata params
    ) external view returns (uint256);

    /// @dev config the trusted sequencer address, only owner can call this function
    /// @param trustedSequencerAddr the address of the trusted sequencer
    /// @param state true is add, false is remove
    function ConfigTrustedSequencer(
        address trustedSequencerAddr,
        bool state
    ) external;

    /// @dev get the message launch nonce of the sender on the specific chain
    /// @param chainId the chain id of the sender
    /// @param sender the address of the sender
    function GetNonceLaunch(
        uint64 chainId,
        address sender
    ) external view returns (uint24);

    /// @dev get the message landing nonce of the sender on the specific chain
    /// @param chainId the chain id of the sender
    /// @param sender the address of the sender
    function GetNonceLanding(
        uint64 chainId,
        address sender
    ) external view returns (uint24);

    /// @dev trusted sequencer, we will execute the message from this address
    /// @return true is trusted sequencer, false is not
    function TrustedSequencer(address) external view returns (bool);

    /// @dev get the version of the Station
    /// @return the version of the Station, like "v1.0.0"
    function Version() external view returns (string memory);

    /// @dev get the chainId of current Station
    /// @return chainId, defined in the L2SupportLib.sol
    function ChainId() external view returns (uint16);
}
