// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IOminiToken {
    function mint(address toAddress, uint256 amount) external;
}
