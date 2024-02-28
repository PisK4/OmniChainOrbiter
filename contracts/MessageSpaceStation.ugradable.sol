// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {MessageCore} from "./core/MessageCore.sol";
import {IMessagePaymentSystem} from "./interface/IMessagePaymentSystem.sol";
import {L2SupportLib} from "./library/L2SupportLib.sol";
import {Errors} from "./library/Errors.sol";

/// the MessageSpaceStation is a contract that user can send cross-chain message to orther chain
/// Launch is the function that user or DApps send cross-chain message to orther chain
/// Landing is the function that trusted sequencer send cross-chain message to the Station
contract MessageSpaceStationUg is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    MessageCore
{
    string public constant override Version = "v1.0.0";
    uint64 public constant override minArrivalTime = 3 minutes;
    uint64 public constant override maxArrivalTime = 30 days;
    uint16 public constant deployChainId = L2SupportLib.NEXUS;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address trustedSequencerAddr,
        address paymentSystemAddr,
        address _owner
    ) public initializer {
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
        TrustedSequencer[trustedSequencerAddr] = true;

        if (paymentSystemAddr == address(0)) {
            revert Errors.InvalidAddress();
        }
        paymentSystem = IMessagePaymentSystem(paymentSystemAddr);
        emit PaymentSystemChanging(paymentSystemAddr);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

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

    function ChainId() public pure override returns (uint16) {
        return deployChainId;
    }

    function Manager() public view override returns (address) {
        return owner();
    }
}
