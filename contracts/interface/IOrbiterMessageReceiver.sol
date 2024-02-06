// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IOrbiterMessageReceiver {
    function receiveMessage(
        uint64 srcChainId,
        uint24 nonce,
        address sender,
        bytes calldata additionalInfo,
        bytes calldata message
    ) external;
}
