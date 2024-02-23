// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MessageSpaceStationCore} from "./MessageSpaceStationCore.sol";
import {Errors} from "./library/Errors.sol";

contract MessageSpaceStation is MessageSpaceStationCore {
    string public constant override Version = "v1.0.0";
    uint64 public constant override minArrivalTime = 3 minutes;
    uint64 public constant override maxArrivalTime = 30 days;

    constructor(
        address trustedSequencerAddr,
        address paymentSystemAddr,
        uint16 chainId
    )
        payable
        MessageSpaceStationCore(
            trustedSequencerAddr,
            paymentSystemAddr,
            chainId
        )
    {}

    function _checkArrivalTime(
        uint64 earlistArrivalTime,
        uint64 latestArrivalTime
    ) internal view override {
        if (
            (earlistArrivalTime < block.timestamp + minArrivalTime) ||
            (latestArrivalTime > block.timestamp + maxArrivalTime) ||
            latestArrivalTime < earlistArrivalTime
        ) {
            revert Errors.ArrivalTimeNotMakeSense();
        }
    }
}
