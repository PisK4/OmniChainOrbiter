// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OminiTokenCore} from "./OminiTokenCore.sol";

contract OminiToken is OminiTokenCore {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _LaunchPad,
        address _LandingPad,
        address _defaultRelayer
    ) OminiTokenCore(_name, _symbol, _LaunchPad, _LandingPad) {
        OMINI_MINIMAL_ARRIVAL_TIME = 3 minutes;
        OMINI_MAXIMAL_ARRIVAL_TIME = 30 days;
        MINIMAL_GAS_LIMIT = 100000;
        MAXIMAL_GAS_LIMIT = 500000;
        DEFAULT_RELAYER = _defaultRelayer;
        _mint(msg.sender, _initialSupply);
    }

    function _tokenHandlingStrategy(uint256 amount) internal override {
        _burn(msg.sender, amount);
    }
}
