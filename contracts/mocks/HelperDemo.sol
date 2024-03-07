// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageSpaceStation} from "../interface/IMessageSpaceStation.sol";
import {Utils} from "../library/Utils.sol";

contract Helper {
    using Utils for bytes;

    function encodeparams(
        IMessageSpaceStation.InteractionLanding calldata params
    ) external pure returns (bytes32 data) {
        data = abi.encode(params).hash();
    }
}
