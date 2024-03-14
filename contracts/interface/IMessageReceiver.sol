// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMessageReceiver {
    function receiveMessage(
        uint64 srcChainId,
        uint24 nonce,
        address sender,
        bytes calldata message
    ) external;
}
