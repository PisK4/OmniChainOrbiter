// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMessageSpaceStation} from "../interface/IMessageSpaceStation.sol";
import {IExpertLandingHandler} from "../interface/IExpertLandingHandler.sol";

contract ExpertLandingHandler is IExpertLandingHandler, Ownable {
    constructor() Ownable(msg.sender) {}

    function handleLandingParams(
        IMessageSpaceStation.InteractionLanding calldata params
    ) external pure override {
        (params);
        // do nothing
    }
}
