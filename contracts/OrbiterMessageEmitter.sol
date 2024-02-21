// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "./interface/IMessageSpaceStation.sol";
import {IOrbiterMessageEmitter} from "./interface/IOrbiterMessageEmitter.sol";
import {Utils} from "./library/Utils.sol";

abstract contract OrbiterMessageEmitter is IOrbiterMessageEmitter {
    /// @dev bellow are the default parameters for the OmniToken,
    ///      we **strongely recommand** to override them in your own contract.
    /// @notice MINIMAL_ARRIVAL_TIME the minimal arrival time for the cross-chain message
    /// @notice MAXIMAL_ARRIVAL_TIME the maximal arrival time for the cross-chain message
    /// @notice MINIMAL_GAS_LIMIT the minimal gas limit for the cross-chain message
    /// @notice MAXIMAL_GAS_LIMIT the maximal gas limit for the cross-chain message
    /// @notice BRIDGE_MODE the default mode for the cross-chain message,
    ///        in OmniToken, we use MessageTypeLib.ARBITRARY_ACTIVATE, targer chain will **ACTIVATE** the message
    /// @notice SELECTED_RELAYER the default relayer for the cross-chain message

    uint64 immutable MINIMAL_ARRIVAL_TIME;
    uint64 immutable MAXIMAL_ARRIVAL_TIME;
    uint24 immutable MINIMAL_GAS_LIMIT;
    uint24 immutable MAXIMAL_GAS_LIMIT;
    bytes1 immutable BRIDGE_MODE;
    address immutable SELECTED_RELAYER;

    IMessageSpaceStation public LaunchPad;

    constructor(address _LaunchPad) {
        LaunchPad = IMessageSpaceStation(_LaunchPad);
    }

    function emit2LaunchPad(
        IMessageSpaceStation.launchMultiMsgParams memory params
    ) public payable override {
        LaunchPad.Launch{value: msg.value}(params);
    }

    function emit2LaunchPad(
        IMessageSpaceStation.launchSingleMsgParams memory params
    ) public payable override {
        LaunchPad.Launch{value: msg.value}(params);
    }

    function converActivateRawMsg(
        activateRawMsg memory rawMsg
    )
        public
        pure
        override
        returns (IMessageSpaceStation.launchMultiMsgParams memory)
    {
        return
            IMessageSpaceStation.launchMultiMsgParams(
                rawMsg.earlistArrivalTime,
                rawMsg.latestArrivalTime,
                rawMsg.relayer,
                rawMsg.sender,
                rawMsg.destChainld,
                rawMsg.aditionParams,
                PacketMessages(
                    rawMsg.mode,
                    rawMsg.gasLimit,
                    rawMsg.targetContarct,
                    rawMsg.message
                )
            );
    }

    /// @notice call this function to packet the message before sending it to the LandingPad contract
    /// @param mode the emmiter mode, check MessageTypeLib.sol for more details
    /// @param gasLimit the gas limit for executing the specific function on the target contract
    /// @param targetContarct the target contract address on the destination chain
    /// @param message the message to be sent to the target contract
    /// @return the packed message
    function PacketMessages(
        bytes1[] memory mode,
        uint24[] memory gasLimit,
        address[] memory targetContarct,
        bytes[] memory message
    ) public pure virtual override returns (bytes[] memory) {
        bytes[] memory signatures = new bytes[](message.length);

        for (uint256 i = 0; i < message.length; i++) {
            signatures[i] = abi.encodePacked(
                mode[i],
                uint256(uint160(targetContarct[i])),
                gasLimit[i],
                message[i]
            );
        }

        return signatures;
    }
}
