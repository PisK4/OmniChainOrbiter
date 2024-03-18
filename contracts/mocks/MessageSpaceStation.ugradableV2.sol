// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {MessageCore, MessageMonitorLib} from "../core/MessageCore.sol";
import {IMessagePaymentSystem} from "../interface/IMessagePaymentSystem.sol";
import {L2SupportLib} from "../library/L2SupportLib.sol";
import {Errors} from "../library/Errors.sol";
import "hardhat/console.sol";

/// the MessageSpaceStation is a contract that user can send cross-chain message to orther chain
/// Launch is the function that user or DApps send cross-chain message to orther chain
/// Landing is the function that trusted sequencer send cross-chain message to the Station
contract MessageSpaceStationUgv2 is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    MessageCore
{
    string public constant override Version = "v5.3.a-beta";
    uint64 public constant override minArrivalTime = 3 minutes;
    uint64 public constant override maxArrivalTime = 30 days;
    uint16 public constant deployChainId = L2SupportLib.VIZING;

    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(
        address trustedSequencerAddr,
        address paymentSystemAddr,
        address _owner
    ) public initializer {
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
        TrustedSequencer[trustedSequencerAddr] = true;
        _isLanding = MessageMonitorLib.LANDING_PAD_FREE;
        _isPaused = MessageMonitorLib.ENGINE_START;

        if (paymentSystemAddr == address(0)) {
            revert Errors.InvalidAddress();
        }
        paymentSystem = IMessagePaymentSystem(paymentSystemAddr);
        emit PaymentSystemChanging(paymentSystemAddr);
    }

    function setConfiguration(bytes calldata config) external view onlyManager {
        (config);
        console.log("setConfiguration");
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function _checkArrivalTime(
        uint64 earlistArrivalTimestamp,
        uint64 latestArrivalTimestamp
    ) internal view override {
        if (
            (earlistArrivalTimestamp < block.timestamp + minArrivalTime) ||
            (latestArrivalTimestamp > block.timestamp + maxArrivalTime) ||
            latestArrivalTimestamp < earlistArrivalTimestamp
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

    /**
     * @dev **For Upgradeable contracts**
     * The size of the __gap array is calculated so that the amount of storage
     * used by a contract always adds up to the same number (in this case 50 storage slots).
     * See https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts
     */
    uint256[50] private __gap;
}
