// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageCore} from "./core/MessageCore.sol";
import {Errors} from "./library/Errors.sol";
import {L2SupportLib} from "./library/L2SupportLib.sol";
import {IMessagePaymentSystem} from "./interface/IMessagePaymentSystem.sol";

contract MessageSpaceStation is Ownable, MessageCore {
    string public constant override Version = "v1.0.0";
    uint64 public constant override minArrivalTime = 3 minutes;
    uint64 public constant override maxArrivalTime = 30 days;

    constructor(
        address trustedRelayerAddr,
        address paymentSystemAddr,
        address admin
    ) payable Ownable(admin) {
        ConfigTrustedRelayer(trustedRelayerAddr, true);
        paymentSystem = IMessagePaymentSystem(paymentSystemAddr);
    }

    function _checkArrivalTime(
        uint64 earlistArrivalTimestamp,
        uint64 latestArrivalTimestamp
    ) internal view override {
        if (
            (earlistArrivalTimestamp > 0 && latestArrivalTimestamp > 0) &&
            ((earlistArrivalTimestamp < block.timestamp + minArrivalTime) ||
                (latestArrivalTimestamp > block.timestamp + maxArrivalTime) ||
                latestArrivalTimestamp < earlistArrivalTimestamp)
        ) {
            revert Errors.ArrivalTimeNotMakeSense();
        }
    }

    function Manager() public view override returns (address) {
        return owner();
    }
}
