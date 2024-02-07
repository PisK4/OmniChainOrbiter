// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOminiToken} from "./interface/IOminiToken.sol";
import {IMessageSpaceStation} from "../../interface/IMessageSpaceStation.sol";

import {MessageTypeLib} from "../../library/MessageTypeLib.sol";

import {OrbiterMessageEmitter} from "../../OrbiterMessageEmitter.sol";
import {OrbiterMessageReceiver} from "../../OrbiterMessageReceiver.sol";

contract OminiToken is
    ERC20,
    OrbiterMessageEmitter,
    OrbiterMessageReceiver,
    IOminiToken,
    Ownable
{
    error InvalidData();

    uint64 immutable OMINI_MINIMAL_ARRIVAL_TIME = 3 minutes;
    uint64 immutable OMINI_MAXIMAL_ARRIVAL_TIME = 30 days;
    uint24 immutable MINIMAL_GAS_LIMIT = 100000;
    uint24 immutable MAXIMAL_GAS_LIMIT = 500000;
    bytes1 immutable DEFAULT_MODE = MessageTypeLib.ARBITRARY_ACTIVATE;
    address immutable DEFAULT_RELAYER;

    // mirror OmniToken : mirrorToken[chainId] = address
    mapping(uint64 => address) public mirrorToken;

    modifier onlyLandingPad() {
        if (msg.sender != address(LandingPad)) revert AccessDenied();
        _;
    }

    modifier onlyLaunchPad() {
        if (msg.sender != address(LaunchPad)) revert AccessDenied();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _LaunchPad,
        address _LandingPad,
        address _defaultRelayer
    )
        ERC20(_name, _symbol)
        OrbiterMessageEmitter(_LaunchPad)
        OrbiterMessageReceiver(_LandingPad)
        Ownable(msg.sender)
    {
        _mint(msg.sender, _initialSupply);
        DEFAULT_RELAYER = _defaultRelayer;
    }

    function mint(
        address toAddress,
        uint256 amount
    ) public override onlyLandingPad {
        _mint(toAddress, amount);
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

    function bridgeTransfer(
        uint64 destChainId,
        address receiver,
        uint256 amount,
        address relayer
    ) external payable override {
        uint64[] memory destChainIdArr = new uint64[](1);
        destChainIdArr[0] = destChainId;

        bytes[] memory message = new bytes[](1);
        message[0] = _fetchSignature(receiver, amount);

        address[] memory targetContract = new address[](1);
        targetContract[0] = mirrorToken[destChainId];

        activateRawMsg memory _activateRawMsg = activateRawMsg({
            destChainld: destChainIdArr,
            earlistArrivalTime: uint64(
                block.timestamp + OMINI_MINIMAL_ARRIVAL_TIME
            ),
            latestArrivalTime: uint64(
                block.timestamp + OMINI_MAXIMAL_ARRIVAL_TIME
            ),
            sender: address(0),
            relayer: relayer,
            mode: new bytes1[](1),
            targetContarct: targetContract,
            gasLimit: new uint24[](1),
            message: message,
            aditionParams: new bytes[](0)
        });
        _tokenHandlingStrategy(amount);
        bridgeTransferHandler(_activateRawMsg);
    }

    function fetchProtocolFee(
        uint64[] calldata destChainId,
        address[] calldata receiver,
        uint256[] calldata amount,
        address relayer
    ) external pure override returns (uint256) {
        if (
            destChainId.length != receiver.length ||
            destChainId.length != amount.length
        ) {
            revert InvalidData();
        }

        return 0;
    }

    function setMirrorToken(
        uint64 chainId,
        address tokenAddress
    ) external onlyOwner {
        mirrorToken[chainId] = tokenAddress;
    }

    /// @dev bellow are the virtual functions, feel free to override them in your own contract.
    /// for Example, you can override the _tokenHandlingStrategy,
    /// instead of burning the token, you can transfer the token to a specific address.
    function _tokenHandlingStrategy(uint256 amount) internal virtual {
        _burn(msg.sender, amount);
    }

    function _fetchSignature(
        address toAddress,
        uint256 amount
    ) internal pure virtual returns (bytes memory signature) {
        signature = abi.encodeCall(IOminiToken.mint, (toAddress, amount));
    }

    function bridgeTransferHandler(
        activateRawMsg memory _activateRawMsg
    ) public virtual {
        if (_activateRawMsg.relayer == address(0)) {
            _activateRawMsg.relayer = DEFAULT_RELAYER;
        }

        if (
            _activateRawMsg.earlistArrivalTime <
            block.timestamp + OMINI_MINIMAL_ARRIVAL_TIME
        ) {
            _activateRawMsg.earlistArrivalTime = uint64(
                block.timestamp + OMINI_MINIMAL_ARRIVAL_TIME
            );
        }

        if (
            _activateRawMsg.latestArrivalTime >
            block.timestamp + OMINI_MAXIMAL_ARRIVAL_TIME
        ) {
            _activateRawMsg.latestArrivalTime = uint64(
                block.timestamp + OMINI_MAXIMAL_ARRIVAL_TIME
            );
        }

        if (_activateRawMsg.sender == address(0)) {
            _activateRawMsg.sender = msg.sender;
        }

        for (uint256 i = 0; i < _activateRawMsg.gasLimit.length; i++) {
            if (_activateRawMsg.gasLimit[i] == 0) {
                _activateRawMsg.gasLimit[i] = MINIMAL_GAS_LIMIT;
            } else if (_activateRawMsg.gasLimit[i] > MAXIMAL_GAS_LIMIT) {
                _activateRawMsg.gasLimit[i] = MAXIMAL_GAS_LIMIT;
            }
        }

        // mode
        for (uint256 i = 0; i < _activateRawMsg.mode.length; i++) {
            if (_activateRawMsg.mode[i] == 0) {
                _activateRawMsg.mode[i] = DEFAULT_MODE;
            }
        }
        emit2LaunchPad(
            IMessageSpaceStation.paramsLaunch(
                _activateRawMsg.destChainld,
                _activateRawMsg.earlistArrivalTime,
                _activateRawMsg.latestArrivalTime,
                _activateRawMsg.sender,
                _activateRawMsg.relayer,
                _activateRawMsg.aditionParams,
                PacketMessages(
                    _activateRawMsg.mode,
                    _activateRawMsg.gasLimit,
                    _activateRawMsg.targetContarct,
                    _activateRawMsg.message
                )
            )
        );
    }
}
