// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "./interface/IMessageSpaceStation.sol";
import {IOrbiterMessageEmitter} from "./interface/IOrbiterMessageEmitter.sol";
import {Utils} from "./library/Utils.sol";
import {Errors} from "./library/Errors.sol";

abstract contract OrbiterMessageEmitter is IOrbiterMessageEmitter {
    struct rawMessage {
        uint64[] destChainld;
        uint64 earlistArrivalTime;
        uint64 latestArrivalTime;
        address sender;
        address relayer;
        bytes1[] mode;
        address[] targetContarct;
        uint24[] gasLimit;
        bytes[] message;
        bytes[] aditionParams;
    }
    IMessageSpaceStation public LaunchPad;

    constructor(address _LaunchPad) {
        LaunchPad = IMessageSpaceStation(_LaunchPad);
    }

    /// @dev put this modifier on the function that you want to emit the cross-chain message
    /// @param _rawMessage the raw message to be sent to the LandingPad contract
    modifier LaunchHook(rawMessage memory _rawMessage) {
        _;
        bytes[] memory _message = new bytes[](_rawMessage.message.length);
        for (uint256 i = 0; i < _rawMessage.message.length; i++) {
            _message[i] = packetMessage(
                _rawMessage.mode[i],
                _rawMessage.gasLimit[i],
                _rawMessage.targetContarct[i],
                _rawMessage.message[i]
            );
        }
        LaunchPad.Launch(
            IMessageSpaceStation.paramsLaunch(
                _rawMessage.destChainld,
                _rawMessage.earlistArrivalTime,
                _rawMessage.latestArrivalTime,
                _rawMessage.sender,
                _rawMessage.relayer,
                _rawMessage.aditionParams,
                _message
            )
        );

        // packetMessage(mode, gasLimit, targetContarct, message);
    }

    function FetchProtocalFee(
        IMessageSpaceStation.paramsLaunch calldata params
    ) external view override returns (uint256) {
        return LaunchPad.FetchProtocalFee(params);
    }

    /// @notice call this function to packet the message before sending it to the LandingPad contract
    /// @param mode the emmiter mode, check MessageTypeLib.sol for more details
    /// @param gasLimit the gas limit for executing the specific function on the target contract
    /// @param targetContarct the target contract address on the destination chain
    /// @param message the message to be sent to the target contract
    /// @return the packed message
    function packetMessage(
        bytes1 mode,
        uint24 gasLimit,
        address targetContarct,
        bytes memory message
    ) public pure virtual override returns (bytes memory) {
        bytes memory signature = abi.encodePacked(
            mode,
            uint256(uint160(targetContarct)),
            gasLimit,
            message
        );
        return signature;
    }

    function _Launch(
        rawMessage memory _rawMessage
    ) internal virtual LaunchHook(_rawMessage) {}
}
