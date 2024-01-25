// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOrbiterStation} from "./interface/IOrbiterStation.sol";
import {Utils} from "./library/Utils.sol";
import {Errors} from "./library/Errors.sol";
import {nonceMonitor, nonceMonitorLib} from "./nonceMonitor.sol";

contract OrbiterStation is IOrbiterStation, nonceMonitor {
    using nonceMonitorLib for mapping(uint64 => mapping(address => uint24));
    using Utils for bytes;

    receive() external payable {}

    constructor() payable {}

    function launch(
        launchParams calldata params
    ) external payable override returns (bytes32 messageId) {
        messageId = abi
            .encode(
                params.destChainld,
                params.sender,
                address(this),
                landNonce[params.destChainld][params.sender]
            )
            .hash();

        launchNonce.update(params.destChainld, params.sender);
    }

    function land(
        bytes[] calldata validatorSignatures,
        landParams calldata params
    ) external override {
        (validatorSignatures);
        if (
            landNonce.compare(
                params.scrChainld,
                params.sender,
                params.launchNonce
            ) != true
        ) {
            revert Errors.NonceNotMatched();
        }
        landNonce.update(params.scrChainld, params.sender);
    }
}
