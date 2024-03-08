// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library MessageTypeLib {
    bytes1 constant DEFAULT = 0x00;
    bytes1 constant SDK_ACTIVATE_V1 = 0x01;
    bytes1 constant ARBITRARY_ACTIVATE = 0x02;
    bytes1 constant MESSAGE_POST = 0x03;
    bytes1 constant MAX_MODE = 0xFF;

    /********************* aditionParams **********************/
    // Single-Send mode
    bytes1 constant SINGLE_SEND = 0x01;
    // Muti-Send mode
    bytes1 constant MULTI_ONE_2_ONE = 0x02;
    bytes1 constant MULTI_ONE_2_MANY = 0x03;
    bytes1 constant MULTI_MANY_2_ONE = 0x04;
    bytes1 constant MULTI_UNIVERSAL = 0x05;

    function fetchMsgMode(
        bytes calldata message
    ) internal pure returns (bytes1) {
        bytes1 messageSlice = bytes1(message[0:1]);
        return messageSlice;
    }
}
