// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMessageStruct} from "../../interface/IMessageStruct.sol";
import {IMessageReceiver} from "../../interface/IMessageReceiver.sol";
import {MessageEmitter} from "../../MessageEmitter.sol";
import {MessageReceiver} from "../../MessageReceiver.sol";

contract VizingNFTStation is MessageEmitter, MessageReceiver, Ownable {
    uint64 public immutable override minArrivalTime;
    uint64 public immutable override maxArrivalTime;
    uint24 public immutable override minGasLimit;
    uint24 public immutable override maxGasLimit;
    bytes1 public immutable override defaultBridgeMode;
    address public immutable override selectedRelayer;
    uint16 public immutable override deployChainId;

    enum NFTStatus {
        warp,
        unwarp,
        mint,
        burn
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _LaunchPad,
        address _LandingPad,
        bytes1 _defaultBridgeMode
    )
        MessageEmitter(_LaunchPad)
        MessageReceiver(_LandingPad)
        Ownable(msg.sender)
    {
        (_name, _symbol);
        defaultBridgeMode = _defaultBridgeMode;
        deployChainId = LaunchPad.ChainId();
    }
}
