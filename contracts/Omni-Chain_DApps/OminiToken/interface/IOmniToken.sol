// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IOmniToken {
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
