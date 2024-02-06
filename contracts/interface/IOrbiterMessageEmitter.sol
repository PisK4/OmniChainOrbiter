// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IMessageSpaceStation.sol";

interface IOrbiterMessageEmitter {
    function FetchProtocalFee(
        IMessageSpaceStation.paramsLaunch calldata params
    ) external view returns (uint256);

    function packetMessage(
        bytes1 mode,
        uint24 gasLimit,
        address toAddress,
        bytes calldata message
    ) external view returns (bytes memory);
}
