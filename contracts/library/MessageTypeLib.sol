// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library MessageTypeLib {
    bytes1 constant DEFAULT = 0x00;
    bytes1 constant SDK_ACTIVATE_V1 = 0x01;
    bytes1 constant ARBITRARY_ACTIVATE = 0x02;
    bytes1 constant MESSAGE_POST = 0x03;
    bytes1 constant MAX_MODE = 0xFF;

    function fetchMessageType(
        bytes calldata message
    ) internal pure returns (bytes1) {
        bytes1 messageSlice = bytes1(message[0:1]);
        return messageSlice;
    }
}
