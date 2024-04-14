// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageChannel} from "./interface/IMessageChannel.sol";
import {IMessageEmitter} from "./interface/IMessageEmitter.sol";
import {IMessageReceiver} from "./interface/IMessageReceiver.sol";
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

    function minArrivalTime() external view virtual override returns (uint64) {}

    function maxArrivalTime() external view virtual override returns (uint64) {}

    function minGasLimit() external view virtual override returns (uint24) {}

    function maxGasLimit() external view virtual override returns (uint24) {}

    function deployChainId() external view virtual override returns (uint16) {}

    function defaultBridgeMode()
        external
        view
        virtual
        override
        returns (bytes1)
    {}

    function selectedRelayer()
        external
        view
        virtual
        override
        returns (address)
    {}

    IMessageChannel public LaunchPad;

    constructor(address _LaunchPad) {
        LaunchPad = IMessageChannel(_LaunchPad);
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

    function _fetchSignature(
        bytes memory message
    ) internal view virtual returns (bytes memory signature) {
        signature = abi.encodeCall(
            IMessageReceiver.receiveMessage,
            (LaunchPad.ChainId(), _fetchNonce(), msg.sender, message)
        );
    }

    function _fetchNonce() internal view virtual returns (uint32 nonce) {
        nonce = LaunchPad.GetNonceLaunch(LaunchPad.ChainId(), msg.sender);
    }
}
