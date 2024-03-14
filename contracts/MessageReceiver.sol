// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "./interface/IMessageSpaceStation.sol";
import {IMessageReceiver} from "./interface/IMessageReceiver.sol";

abstract contract MessageReceiver is IMessageReceiver {
    error LandingPadAccessDenied();
    error NotImplement();
    IMessageSpaceStation public LandingPad;

    modifier onlyLandingPad() {
        if (msg.sender != address(LandingPad)) revert LandingPadAccessDenied();
        _;
    }

    constructor(address _LandingPad) {
        LandingPad = IMessageSpaceStation(_LandingPad);
    }

    /// @notice the standard function to receive the cross-chain message
    function receiveMessage(
        uint64 srcChainId,
        uint24 nonce,
        address sender,
        bytes calldata message
    ) external virtual onlyLandingPad {
        _receiveMessage(srcChainId, nonce, sender, message);
    }

    /// @dev override this function to handle the cross-chain message
    /// @param srcChainId the source chain id
    /// @param nonce the message nonce
    /// @param sender the message sender from the source chain
    /// @param message the message from the source chain
    function _receiveMessage(
        uint64 srcChainId,
        uint24 nonce,
        address sender,
        bytes calldata message
    ) internal virtual {
        (srcChainId, nonce, sender, message);
        revert NotImplement();
    }
}
