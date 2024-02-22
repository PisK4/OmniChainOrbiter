// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "./interface/IMessageSpaceStation.sol";
import {IMessageEmitter} from "./interface/IMessageEmitter.sol";
import {Utils} from "./library/Utils.sol";

abstract contract MessageEmitter is IMessageEmitter {
    /// @dev bellow are the default parameters for the OmniToken,
    ///      we **strongely recommand** to use immutable variables to store these parameters
    /// @notice minArrivalTime the minimal arrival time for the cross-chain message
    /// @notice maxArrivalTime the maximal arrival time for the cross-chain message
    /// @notice minGasLimit the minimal gas limit for target chain excute cross-chain message
    /// @notice maxGasLimit the maximal gas limit for target chain excute cross-chain message
    /// @notice defaultBridgeMode the default mode for the cross-chain message,
    ///        in OmniToken, we use MessageTypeLib.ARBITRARY_ACTIVATE, targer chain will **ACTIVATE** the message
    /// @notice selectedRelayer the default relayer for the cross-chain message

    uint64 public immutable override minArrivalTime;
    uint64 public immutable override maxArrivalTime;
    uint24 public immutable override minGasLimit;
    uint24 public immutable override maxGasLimit;
    bytes1 public immutable override defaultBridgeMode;
    address public immutable override selectedRelayer;

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
