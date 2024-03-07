// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IOmniTokenCore {
    struct activateRawMsg {
        uint16[] destChainld;
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
        uint16 destChainId,
        address receiver,
        uint256 amount
    ) external payable;

    function fetchOmniTokenTransferFee(
        uint16[] calldata destChainId,
        address[] calldata receiver,
        uint256[] calldata amount
    ) external view returns (uint256);
}
