// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IDepositSpaceStation {
    event Register(address indexed newValidator, uint256 amount);
    event WithdarwRequest(address indexed validator, uint64 targetWithdrawTime);
    event Withdarw(address indexed validator);

    function setMinimalDeposit(uint256 amount) external;

    function fetchMinimalDeposit() external view returns (uint256);

    function setMinimalWithdrawDelay(uint64 delaySeconds) external;

    function fetchMinimalWithdrawDelay() external view returns (uint64);

    function setSubmitter(address newSubmitter) external;

    function submitSmtRoot(bytes32 root) external;

    function register() external payable;

    function withdarw(bytes32[] calldata proof, uint256 amount) external;
}
