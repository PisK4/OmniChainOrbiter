// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import {Errors} from "./library/Errors.sol";

library MessageMonitorLib {
    using MessageMonitorLib for address;
    bytes1 constant MAIL = 0x00;
    bytes1 constant EXCUTE = 0x01;

    uint8 constant ENGINE_STOP = 0x01;
    uint8 constant ENGINE_START = 0x02;

    uint16 constant returnDataSize = 32;

    function update(
        mapping(uint64 => mapping(address => uint24)) storage self,
        uint64 chainId,
        address sender
    ) internal {
        self[chainId][sender]++;
    }

    function compare(
        mapping(uint64 => mapping(address => uint24)) storage self,
        uint64 chainId,
        address sender,
        uint24 nonceLaunch
    ) internal view returns (bool) {
        return self[chainId][sender] == nonceLaunch;
    }

    function fetchMessageType(
        bytes calldata message
    ) internal pure returns (bytes1) {
        bytes1 messageSlice = bytes1(message[0:1]);
        return messageSlice;
    }

    function excuteSignature(
        bytes calldata message
    ) internal returns (bool success, bytes memory returnData) {
        // note: byte1 ~ byte33 is contract address
        address contractAddr = address(
            uint160(uint256(bytes32(message[1:33])))
        );
        // note: byte33 ~ byte35 is gasLimit
        uint24 gasLimit = (uint24(bytes3(message[33:36])));
        uint256 value = 0;
        /// note: byte36 ~ byteEnd is signature
        bytes memory signature = message[36:message.length];

        // excute signature on specific contract address
        (success, returnData) = contractAddr.safeCall(
            gasLimit,
            value,
            returnDataSize,
            signature
        );
    }

    function safeCall(
        address _target,
        uint256 _gas,
        uint256 _value,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                _value, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }
}

abstract contract MessageMonitor {
    mapping(uint64 => mapping(address => uint24)) public nonceLaunch;
    mapping(uint64 => mapping(address => uint24)) public nonceLanding;
}
