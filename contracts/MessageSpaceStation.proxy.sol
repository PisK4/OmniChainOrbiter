// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MessageSpaceStationCoreUPG} from "./MessageSpaceStationCore.proxy.sol";
import {IMessagePaymentSystem} from "./interface/IMessagePaymentSystem.sol";

import {Errors} from "./library/Errors.sol";

contract MessageSpaceStationUPG is MessageSpaceStationCoreUPG {
    string public constant override Version = "v1.0.0";
    uint64 public constant override minArrivalTime = 3 minutes;
    uint64 public constant override maxArrivalTime = 30 days;
    uint16 public constant currentChainId = 1;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address trustedSequencerAddr,
        address paymentSystemAddr,
        address _owner,
        address _adminAddress
    ) public initializer {
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _adminAddress);
        _grantRole(MINTER_ROLE, _adminAddress);
        _grantRole(UPGRADER_ROLE, _adminAddress);

        TrustedSequencer[trustedSequencerAddr] = true;

        if (paymentSystemAddr == address(0)) {
            revert Errors.InvalidAddress();
        }
        paymentSystem = IMessagePaymentSystem(paymentSystemAddr);
        emit PaymentSystemChanging(paymentSystemAddr);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

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
        return currentChainId;
    }
}
