// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IOminiToken {
    function mint(address toAddress, uint256 amount) external;

    function bridgeTransfer(
        uint64 destChainId,
        address receiver,
        uint256 amount
    ) external payable;

    function fetchOminiTokenTransferFee(
        uint64[] calldata destChainId,
        address[] calldata receiver,
        uint256[] calldata amount
    ) external view returns (uint256);
}
