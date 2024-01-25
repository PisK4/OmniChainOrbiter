// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library nonceMonitorLib {
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
}

abstract contract nonceMonitor {
    mapping(uint64 => mapping(address => uint24)) public launchNonce;
    mapping(uint64 => mapping(address => uint24)) public landNonce;
}
