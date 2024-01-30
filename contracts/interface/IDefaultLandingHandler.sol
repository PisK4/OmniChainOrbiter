// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "./IMessageSpaceStation.sol";

interface IDefaultLandingHandler {
    function handleLandingParams(
        IMessageSpaceStation.paramsLanding calldata params
    ) external;
}
