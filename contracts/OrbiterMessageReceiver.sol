// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "./interface/IMessageSpaceStation.sol";
import {IOrbiterMessageReceiver} from "./interface/IOrbiterMessageReceiver.sol";

abstract contract OrbiterMessageReceiver is IOrbiterMessageReceiver {
    error AccessDenied();
    IMessageSpaceStation public LandingPad;

    constructor(address _LandingPad) {
        LandingPad = IMessageSpaceStation(_LandingPad);
    }

    /// @notice the standard function to receive the cross-chain message
    function receiveMessage(
        uint64 srcChainId,
        uint24 nonce,
        address sender,
        bytes calldata additionalInfo,
        bytes calldata message
    ) external virtual {
        if (msg.sender != address(LandingPad)) {
            revert AccessDenied();
        }

        _receiveMessage(srcChainId, nonce, sender, additionalInfo, message);
    }

    /// @dev override this function to handle the cross-chain message
    /// @param srcChainId the source chain id
    /// @param nonce the message nonce
    /// @param sender the message sender from the source chain
    /// @param additionalInfo the additional info from LandingPad contract, discuss with the Orbiter team to finalize the type of additionalInfo
    /// @param message the message from the source chain
    function _receiveMessage(
        uint64 srcChainId,
        uint24 nonce,
        address sender,
        bytes calldata additionalInfo,
        bytes calldata message
    ) internal virtual {}
}
