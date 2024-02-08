// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IMessagePaymentSystem} from "./interface/IMessagePaymentSystem.sol";
import {IMessageSpaceStation} from "./interface/IMessageSpaceStation.sol";
import {IOrbiterMessageEmitter} from "./interface/IOrbiterMessageEmitter.sol";

import {MessageMonitorLib} from "./MessageMonitor.sol";

import {Utils} from "./library/Utils.sol";
import {Errors} from "./library/Errors.sol";

/// DApp should pay the protocol fee to the Station before they send the cross-chain message
/// MessagePaymentSystem is the contract that calculate the protocol fee
/// anyone can call the fetchProtocolFee function to get the protocol fee for free
contract MessagePaymentSystem is IMessagePaymentSystem, Ownable {
    using MessageMonitorLib for mapping(uint64 => mapping(address => uint24));
    using MessageMonitorLib for bytes;
    using MessageMonitorLib for uint24;
    using Utils for bytes;

    constructor() Ownable(msg.sender) {}

    function fetchProtocolFee_(
        IMessageSpaceStation.launchMultiMsgParams calldata params
    ) external pure override returns (uint256) {
        (params);
        return (0.1 ether);
    }

    function fetchProtocolFee_(
        IOrbiterMessageEmitter.activateRawMsg calldata params
    ) external pure override returns (uint256) {
        (params);
        return (0.1 ether);
    }

    function fetchProtocolFee_(
        IMessageSpaceStation.launchSingleMsgParams calldata params
    ) external pure override returns (uint256) {
        (params);
        return (0.1 ether);
    }
}
