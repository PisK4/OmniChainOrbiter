// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

interface IMessageSpaceStation is IMessageStruct {
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
        uint16 chainId,
        address sender
    ) external view returns (uint24);

    /// @dev get the message landing nonce of the sender on the specific chain
    /// @param chainId the chain id of the sender
    /// @param sender the address of the sender
    function GetNonceLanding(
        uint16 chainId,
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

    function Manager() external view returns (address);

    function minArrivalTime() external view returns (uint64);

    function maxArrivalTime() external view returns (uint64);
}
