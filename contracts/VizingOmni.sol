// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MessageEmitter} from "./MessageEmitter.sol";
import {MessageReceiver} from "./MessageReceiver.sol";

abstract contract VizingOmni is MessageEmitter, MessageReceiver {
    constructor(
        address _LaunchPad
    ) MessageEmitter(_LaunchPad) MessageReceiver(_LaunchPad) {}
}
