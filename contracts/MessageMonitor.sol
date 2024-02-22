// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import {IMessageReceiver} from "./interface/IMessageReceiver.sol";
import {Errors} from "./library/Errors.sol";
import {Utils} from "./library/Utils.sol";

library MessageMonitorLib {
    using MessageMonitorLib for address;
    using Utils for bytes;

    uint8 constant ENGINE_STOP = 0x01;
    uint8 constant ENGINE_START = 0x02;

    uint8 constant LANDING_PAD_FREE = 0x01;
    uint8 constant LANDING_PAD_OCCUPIED = 0x02;

    uint16 constant returnDataSize = 32;

    function update(
        mapping(bytes32 => uint24) storage self,
        uint64 chainId,
        address sender
    ) internal {
        self[abi.encode(chainId, sender).hash()]++;
    }

    function update(
        mapping(bytes32 => uint24) storage self,
        bytes32 nonceKey
    ) internal {
        self[nonceKey]++;
    }

    function updates(
        mapping(bytes32 => uint24) storage self,
        uint64 chainId,
        address sender,
        uint24 updateTimes
    ) internal {
        self[abi.encode(chainId, sender).hash()] += updateTimes;
    }

    function updates(
        mapping(bytes32 => uint24) storage self,
        bytes32 nonceKey,
        uint24 updateTimes
    ) internal {
        self[nonceKey] += updateTimes;
    }

    function compare(
        mapping(bytes32 => uint24) storage self,
        uint64 chainId,
        address sender,
        uint24 nonceLaunch
    ) internal view returns (bool) {
        return self[abi.encode(chainId, sender).hash()] == nonceLaunch;
    }

    function fetchMessageId(
        mapping(bytes32 => uint24) storage self,
        uint256 srcChainId,
        uint64 destChainId,
        address sender,
        address launchPad
    ) internal view returns (bytes32 messageId) {
        bytes32 nonceLaunchKey = abi.encode(destChainId, sender).hash();
        messageId = abi
            .encode(self[nonceLaunchKey], srcChainId, nonceLaunchKey, launchPad)
            .hash();
    }

    function handling(
        mapping(bytes32 => uint24) storage self,
        uint256 srcChainId,
        uint64 destChainId,
        address sender,
        address launchPad
    ) internal returns (bytes32 messageId) {
        bytes32 nonceLaunchKey = abi.encode(destChainId, sender).hash();
        messageId = abi
            .encode(self[nonceLaunchKey], srcChainId, nonceLaunchKey, launchPad)
            .hash();
        self[nonceLaunchKey]++;
    }

    function allocMessageId(
        uint256 length
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory messageIds = new bytes32[](length);
        return messageIds;
    }

    function fetchNonce(
        mapping(bytes32 => uint24) storage self,
        uint64 chainId,
        address sender
    ) internal view returns (uint24) {
        return self[abi.encode(chainId, sender).hash()];
    }

    function activateArbitrarySig(
        bytes calldata message,
        bytes calldata aditionParams
    ) internal returns (bool success, bytes memory returnData) {
        (address contractAddr, uint24 gasLimit) = sliceMessage(aditionParams);

        uint256 value = 0;

        // excute signature on specific contract address
        (success, returnData) = contractAddr.safeCall(
            gasLimit,
            value,
            returnDataSize,
            message
        );
    }

    function sliceMessage(
        bytes calldata message
    )
        internal
        pure
        returns (
            address contractAddr,
            uint24 gasLimit /*, bytes memory signature*/
        )
    {
        // note: byte1 ~ byte33 is contract address
        contractAddr = address(uint160(uint256(bytes32(message[1:33]))));
        // note: byte33 ~ byte35 is gasLimit
        gasLimit = (uint24(bytes3(message[33:36])));
        // /// note: byte36 ~ byteEnd is signature
        // signature = message[36:message.length];
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
    using MessageMonitorLib for bytes;
    mapping(bytes32 => uint24) public nonceLaunch;
    mapping(bytes32 => uint24) public nonceLanding;

    // function _activateSDKSig(bytes calldata message) internal virtual {
    //     (
    //         address contractAddr,
    //         uint24 gasLimit,
    //         bytes memory signature
    //     ) = message.sliceMessage();
    //     uint256 gasBefore = gasleft();
    //     IMessageReceiver(contractAddr).receiveMessage(
    //         uint64(block.chainid),
    //         nonceLaunch[uint64(block.chainid)][msg.sender],
    //         msg.sender,
    //         new bytes(0),
    //         signature
    //     );
    //     if (gasBefore - gasleft() > gasLimit) {
    //         revert Errors.OutOfGas();
    //     }
    // }
}
