// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IOminiToken} from "./interface/IOminiToken.sol";

import {MessageTypeLib} from "../../library/MessageTypeLib.sol";

import {OrbiterMessageEmitter} from "../../OrbiterMessageEmitter.sol";
import {OrbiterMessageReceiver} from "../../OrbiterMessageReceiver.sol";

contract OminiToken is
    ERC20,
    OrbiterMessageEmitter,
    OrbiterMessageReceiver,
    IOminiToken
{
    uint64 immutable MINIMAL_ARRIVAL_TIME = 3 minutes;
    uint64 immutable MAXIMAL_ARRIVAL_TIME = 30 days;
    uint24 immutable MINIMAL_GAS_LIMIT = 100000;
    uint24 immutable MAXIMAL_GAS_LIMIT = 500000;
    bytes1 immutable DEFAULT_MODE = MessageTypeLib.SDK_ACTIVATE_V1;
    address immutable DEFAULT_RELAYER;

    modifier onlyLandingPad() {
        if (msg.sender != address(LandingPad)) revert AccessDenied();
        _;
    }

    modifier onlyLaunchPad() {
        if (msg.sender != address(LaunchPad)) revert AccessDenied();
        _;
    }

    constructor(
        address _LaunchPad,
        address _LandingPad,
        address _defaultRelayer
    )
        ERC20("Omini Orbiter token", "OOT")
        OrbiterMessageEmitter(_LaunchPad)
        OrbiterMessageReceiver(_LandingPad)
    {
        _mint(msg.sender, 10 ether);
        DEFAULT_RELAYER = _defaultRelayer;
    }

    function mint(
        address toAddress,
        uint256 amount
    ) public override onlyLandingPad {
        _mint(toAddress, amount * (1 ether));
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function _receiveMessage(
        uint64 srcChainId,
        uint24 nonce,
        address sender,
        bytes calldata additionalInfo,
        bytes calldata message
    ) internal override {
        (srcChainId, nonce, sender, additionalInfo);
        // decode the message, args is for mint(address toAddress, uint256 amount)
        (address toAddress, uint256 amount) = abi.decode(
            message,
            (address, uint256)
        );
        mint(toAddress, amount);
    }

    function brideTransfer(
        uint64 destChainId,
        address receiver,
        uint256 amount,
        address relayer
    ) external {
        uint64[] memory destChainIdArr = new uint64[](1);
        destChainIdArr[0] = destChainId;

        bytes[] memory message = new bytes[](1);
        message[0] = _fetchSignature(receiver, amount);

        rawMessage memory _rawMessage = rawMessage({
            destChainld: destChainIdArr,
            earlistArrivalTime: uint64(block.timestamp + MINIMAL_ARRIVAL_TIME),
            latestArrivalTime: uint64(block.timestamp + MAXIMAL_ARRIVAL_TIME),
            sender: address(0),
            relayer: relayer,
            mode: new bytes1[](1),
            targetContarct: new address[](1),
            gasLimit: new uint24[](1),
            message: message,
            aditionParams: new bytes[](0)
        });
        _Launch(_rawMessage);
        _tokenHandlingStrategy(amount);
    }

    /// @dev bellow are the virtual functions, feel free to override them in your own contract.
    /// for Example, you can override the _tokenHandlingStrategy,
    /// instead of burning the token, you can transfer the token to a specific address.
    function _tokenHandlingStrategy(uint256 amount) internal virtual {
        _burn(msg.sender, amount * 1 ether);
    }

    function _fetchSignature(
        address toAddress,
        uint256 amount
    ) internal pure virtual returns (bytes memory signature) {
        signature = abi.encodeCall(IOminiToken.mint, (toAddress, amount));
    }

    function _Launch(
        rawMessage memory _rawMessage
    ) internal override LaunchHook(_rawMessage) {
        if (_rawMessage.relayer == address(0)) {
            _rawMessage.relayer = DEFAULT_RELAYER;
        }

        if (
            _rawMessage.earlistArrivalTime <
            block.timestamp + MINIMAL_ARRIVAL_TIME
        ) {
            _rawMessage.earlistArrivalTime = uint64(
                block.timestamp + MINIMAL_ARRIVAL_TIME
            );
        }

        if (
            _rawMessage.latestArrivalTime >
            block.timestamp + MAXIMAL_ARRIVAL_TIME
        ) {
            _rawMessage.latestArrivalTime = uint64(
                block.timestamp + MAXIMAL_ARRIVAL_TIME
            );
        }

        if (_rawMessage.sender == address(0)) {
            _rawMessage.sender = msg.sender;
        }

        for (uint256 i = 0; i < _rawMessage.gasLimit.length; i++) {
            if (_rawMessage.gasLimit[i] == 0) {
                _rawMessage.gasLimit[i] = MINIMAL_GAS_LIMIT;
            } else if (_rawMessage.gasLimit[i] > MAXIMAL_GAS_LIMIT) {
                _rawMessage.gasLimit[i] = MAXIMAL_GAS_LIMIT;
            }
        }

        // mode
        for (uint256 i = 0; i < _rawMessage.mode.length; i++) {
            if (_rawMessage.mode[i] == 0) {
                _rawMessage.mode[i] = DEFAULT_MODE;
            }
        }
    }
}
