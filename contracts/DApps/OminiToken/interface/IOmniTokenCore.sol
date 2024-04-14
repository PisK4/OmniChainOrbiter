// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IOmniTokenCore {
    struct activateRawMsg {
        uint64[] destChainld;
        uint64 earlistArrivalTimestamp;
        uint64 latestArrivalTimestamp;
        address sender;
        address relayer;
        bytes1[] mode;
        address[] targetContarct;
        uint24[] gasLimit;
        bytes[] message;
        bytes[] aditionParams;
    }

    function mint(address toAddress, uint256 amount) external;

    function bridgeTransfer(
        uint64 destChainId,
        address receiver,
        uint256 amount
    ) external payable;

    function fetchOmniTokenTransferFee(
        uint64[] calldata destChainId,
        address[] calldata receiver,
        uint256[] calldata amount
    ) external view returns (uint256);
}
