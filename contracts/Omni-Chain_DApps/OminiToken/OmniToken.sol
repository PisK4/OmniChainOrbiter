// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OmniTokenCore} from "./OmniTokenCore.sol";

contract OmniToken is OmniTokenCore {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _LaunchPad,
        address _LandingPad,
        address _defaultRelayer
    ) OmniTokenCore(_name, _symbol, _LaunchPad, _LandingPad) {
        minArrivalTime = 3 minutes;
        maxArrivalTime = 30 days;
        minGasLimit = 100000;
        maxGasLimit = 500000;
        selectedRelayer = _defaultRelayer;
        _mint(msg.sender, _initialSupply);
    }

    function _tokenHandlingStrategy(uint256 amount) internal override {
        _burn(msg.sender, amount);
    }
}
