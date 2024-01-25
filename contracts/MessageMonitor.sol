// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library MessageMonitorLib {
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
        uint24 launchNonce
    ) internal view returns (bool) {
        return self[chainId][sender] == launchNonce;
    }

    function getType(bytes calldata message) public pure returns (bytes1) {
        bytes1 messageSlice = bytes1(message[0:1]);
        return messageSlice;
    }

    function excuteSignature(bytes calldata message) internal returns (bool) {
        // note: byte1 ~ byte33 is contract address
        address contractAddr = address(
            uint160(uint256(bytes32(message[1:33])))
        );
        // note: byte33 ~ byte36 is gasLimit
        uint24 gasLimit = uint24(uint256(bytes32(message[33:37])));
        /// note: byte37 ~ byteEnd is signature
        bytes memory signature = message[37:message.length];

        // excute signature on specific contract address
        (bool success, ) = contractAddr.call{gas: gasLimit}(signature);
        return success;
    }
}

abstract contract MessageMonitor {
    mapping(uint64 => mapping(address => uint24)) public launchNonce;
    mapping(uint64 => mapping(address => uint24)) public landNonce;
}
