// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IMessageSpaceStation.sol";

interface IMessageEmitter {
    function minArrivalTime() external view returns (uint64);

    function maxArrivalTime() external view returns (uint64);

    function minGasLimit() external view returns (uint24);

    function maxGasLimit() external view returns (uint24);

    function defaultBridgeMode() external view returns (bytes1);

    function selectedRelayer() external view returns (address);

    function deployChainId() external view returns (uint64);

    function PacketMessages(
        bytes1[] memory mode,
        uint24[] memory gasLimit,
        address[] memory targetContarct,
        bytes[] memory message
    ) external view returns (bytes[] memory);
}
