// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMessageSpaceStation} from "../interface/IMessageSpaceStation.sol";
import {IDefaultLandingHandler} from "../interface/IDefaultLandingHandler.sol";

contract DefaultLandingHandler is IDefaultLandingHandler, Ownable {
    constructor() Ownable(msg.sender) {}

    function handleLandingParams(
        IMessageSpaceStation.paramsLanding calldata params
    ) external pure override {
        (params);
        // do nothing
    }
}
