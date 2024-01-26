// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMessageSpaceStation} from "./interface/IMessageSpaceStation.sol";
import {Utils} from "./library/Utils.sol";
import {Errors} from "./library/Errors.sol";
import {MessageMonitor, MessageMonitorLib} from "./MessageMonitor.sol";

contract MessageSpaceStation is IMessageSpaceStation, MessageMonitor, Ownable {
    using MessageMonitorLib for mapping(uint64 => mapping(address => uint24));
    using MessageMonitorLib for bytes;
    using Utils for bytes;

    /// @dev trusted sequencer, we will execute the message from this address
    address public trustedSequencer;
    /// @dev engine status 0x01 is stop, 0x02 is start
    uint8 public isPause;

    receive() external payable {}

    constructor(address _trustedSequencer) payable Ownable(msg.sender) {
        trustedSequencer = _trustedSequencer;
    }

    modifier engineCheck() {
        if (isPause == MessageMonitorLib.ENGINE_STOP) {
            revert Errors.isPause();
        }
        _;
    }

    function Launch(
        LaunchParams calldata params
    ) external payable override engineCheck returns (bytes32 messageId) {
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

    function Land(
        bytes[] calldata validatorSignatures,
        LandParams calldata params
    ) external override engineCheck {
        if (msg.sender != trustedSequencer) {
            revert Errors.NotTrustedSequencer();
        }
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

        if (params.message.fetchMessageType() == MessageMonitorLib.EXCUTE) {
            params.message.excuteSignature();
        }
    }

    function pause(bool _isPause) external override onlyOwner {
        if (_isPause) {
            isPause = MessageMonitorLib.ENGINE_STOP;
        } else {
            isPause = MessageMonitorLib.ENGINE_START;
        }
    }

    function withdarw(uint256 amount) external override {
        (bool sent, ) = payable(owner()).call{value: amount}("");
        if (!sent) {
            revert Errors.WithdrawError();
        }
    }
}
