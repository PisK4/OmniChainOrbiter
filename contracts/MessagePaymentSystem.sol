// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageMonitorLib} from "./MessageMonitor.sol";
import {IMessagePaymentSystem} from "./interface/IMessagePaymentSystem.sol";
import {IMessageSpaceStation} from "./interface/IMessageSpaceStation.sol";
import {Utils} from "./library/Utils.sol";
import {Errors} from "./library/Errors.sol";

/// DApp should pay the protocol fee to the Station before they send the cross-chain message
/// MessagePaymentSystem is the contract that calculate the protocol fee
/// anyone can call the fetchProtocalFee function to get the protocol fee for free
contract MessagePaymentSystem is IMessagePaymentSystem, Ownable {
    using MessageMonitorLib for mapping(uint64 => mapping(address => uint24));
    using MessageMonitorLib for bytes;
    using MessageMonitorLib for uint24;
    using Utils for bytes;

    constructor() Ownable(msg.sender) {}

    function fetchProtocalFee_(
        IMessageSpaceStation.paramsLaunch calldata params
    ) external pure override returns (uint256) {
        (params);
        return 0;
    }
}
