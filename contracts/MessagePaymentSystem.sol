// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageMonitorLib} from "./MessageMonitor.sol";
import {IMessagePaymentSystem} from "./interface/IMessagePaymentSystem.sol";
import {Utils} from "./library/Utils.sol";
import {Errors} from "./library/Errors.sol";

contract MessagePaymentSystem is IMessagePaymentSystem, Ownable {
    using MessageMonitorLib for mapping(uint64 => mapping(address => uint24));
    using MessageMonitorLib for bytes;
    using MessageMonitorLib for uint24;
    using Utils for bytes;

    receive() external payable {}

    constructor() payable Ownable(msg.sender) {}

    function fetchProtocalFee(
        MessageMonitorLib.paramsLaunch calldata params
    ) public pure override returns (uint256) {
        (params);
        return 0;
    }
}
