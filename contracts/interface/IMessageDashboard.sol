// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

interface IMessageDashboard is IMessageStruct {
    /// @dev Only owner can call this function to stop or restart the engine
    /// @param stop true is stop, false is start
    function PauseEngine(bool stop) external;

    /// @notice return the status of the engine
    /// @return 0x01 is stop, 0x02 is start
    function isPaused() external view returns (uint8);

    // function mptRoot() external view returns (bytes32);

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

    /// @dev trusted sequencer, we will execute the message from this address
    /// @return true is trusted sequencer, false is not
    function TrustedSequencer(address) external view returns (bool);

    function Manager() external view returns (address);
}
