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
        MINIMAL_ARRIVAL_TIME = 3 minutes;
        MAXIMAL_ARRIVAL_TIME = 30 days;
        MINIMAL_GAS_LIMIT = 100000;
        MAXIMAL_GAS_LIMIT = 500000;
        DEFAULT_RELAYER = _defaultRelayer;
        _mint(msg.sender, _initialSupply);
    }

    function _tokenHandlingStrategy(uint256 amount) internal override {
        _burn(msg.sender, amount);
    }
}
