// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "./IMessageSpaceStation.sol";

interface IExpertLandingHandler {
    function handleLandingParams(
        IMessageSpaceStation.InteractionLanding calldata params
    ) external;
}
