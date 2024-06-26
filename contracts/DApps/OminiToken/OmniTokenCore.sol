// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOmniTokenCore} from "./interface/IOmniTokenCore.sol";
import {IMessageStruct} from "../../interface/IMessageStruct.sol";
import {IMessageReceiver} from "../../interface/IMessageReceiver.sol";
import {MessageEmitter} from "../../MessageEmitter.sol";
import {MessageReceiver} from "../../MessageReceiver.sol";

abstract contract OmniTokenCore is
    ERC20,
    MessageEmitter,
    MessageReceiver,
    IOmniTokenCore,
    Ownable
{
    error InvalidData();

    uint64 public immutable override minArrivalTime;
    uint64 public immutable override maxArrivalTime;
    uint24 public immutable override minGasLimit;
    uint24 public immutable override maxGasLimit;
    bytes1 public immutable override defaultBridgeMode;
    address public immutable override selectedRelayer;
    uint64 public immutable override deployChainId;
    // mirror OmniToken : mirrorToken[chainId] = address
    mapping(uint64 => address) public mirrorToken;

    constructor(
        string memory _name,
        string memory _symbol,
        address _LaunchPad,
        address _LandingPad,
        bytes1 _defaultBridgeMode
    )
        ERC20(_name, _symbol)
        MessageEmitter(_LaunchPad)
        MessageReceiver(_LandingPad)
        Ownable(msg.sender)
    {
        defaultBridgeMode = _defaultBridgeMode;
        deployChainId = LaunchPad.ChainId();
    }

    function mint(
        address toAddress,
        uint256 amount
    ) public virtual override onlyLandingPad {
        _mint(toAddress, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function bridgeTransfer(
        uint64 destChainId,
        address receiver,
        uint256 amount
    ) external payable virtual override {
        _tokenHandlingStrategy(amount);
        bridgeTransferHandler(destChainId, receiver, amount);
    }

    function setMirrorToken(
        uint64 chainId,
        address tokenAddress
    ) external onlyOwner {
        mirrorToken[chainId] = tokenAddress;
    }

    function bridgeTransferHandler(
        uint64[] calldata destChainId,
        address[] calldata receiver,
        uint256[] calldata amount
    ) public {
        // uint64[] memory destChainIdArr = new uint64[](1);
        // destChainIdArr[0] = destChainId;
        // bytes[] memory message = new bytes[](1);
        // message[0] = _fetchSignature(receiver, amount);
        // address[] memory targetContract = new address[](1);
        // targetContract[0] = mirrorToken[destChainId];
        // bytes1[] memory mode = new bytes1[](1);
        // mode[0] = MessageTypeLib.ARBITRARY_ACTIVATE;
        // uint24[] memory gasLimit = new uint24[](1);
        // gasLimit[0] = minGasLimit;
        // emit2LaunchPad(
        //     IMessageStruct.launchMultiMsgParams(
        //         destChainIdArr,
        //         uint64(block.timestamp + minArrivalTime),
        //         uint64(block.timestamp + maxArrivalTime),
        //         msg.sender,
        //         selectedRelayer,
        //         new bytes[](0),
        //         PacketMessages(mode, gasLimit, targetContract, message)
        //     )
        // );
    }

    function bridgeTransferHandler(
        uint64 destChainId,
        address receiver,
        uint256 amount
    ) public payable virtual {
        emit2LaunchPad(
            IMessageStruct.launchSingleMsgParams(
                uint64(block.timestamp + minArrivalTime),
                uint64(block.timestamp + maxArrivalTime),
                selectedRelayer,
                msg.sender,
                0,
                destChainId,
                new bytes(0),
                abi.encodePacked(
                    defaultBridgeMode,
                    uint256(uint160(mirrorToken[destChainId])),
                    maxGasLimit,
                    _fetchSignature(receiver, amount)
                )
            )
        );
    }

    /// @notice before you bridgeTransfer, please call this function to get the bridge fee
    /// @dev if your token would charge a extra fee, you can override this function
    /// @return the fee of the bridge transfer
    function fetchOmniTokenTransferFee(
        uint64[] calldata destChainId,
        address[] calldata receiver,
        uint256[] calldata amount
    ) external view virtual override returns (uint256) {
        if (
            destChainId.length != receiver.length ||
            destChainId.length != amount.length
        ) {
            revert InvalidData();
        }

        (
            bytes[] memory message,
            address[] memory targetContract,
            bytes1[] memory mode,
            uint24[] memory gasLimit
        ) = _allocMemory(destChainId, receiver, amount);

        return
            LaunchPad.EstimateFee(
                IMessageStruct.launchMultiMsgParams(
                    uint64(block.timestamp + minArrivalTime),
                    uint64(block.timestamp + maxArrivalTime),
                    selectedRelayer,
                    msg.sender,
                    new uint256[](0),
                    destChainId,
                    new bytes[](0),
                    PacketMessages(mode, gasLimit, targetContract, message)
                )
            );
    }

    function _allocMemory(
        uint64[] calldata destChainId,
        address[] calldata receiver,
        uint256[] calldata amount
    )
        internal
        view
        virtual
        returns (
            bytes[] memory,
            address[] memory,
            bytes1[] memory,
            uint24[] memory
        )
    {
        uint256 dataLength = destChainId.length;
        bytes[] memory message = new bytes[](dataLength);
        for (uint256 i = 0; i < dataLength; i++) {
            message[i] = _fetchSignature(receiver[i], amount[i]);
        }

        address[] memory targetContract = new address[](dataLength);
        for (uint256 i = 0; i < dataLength; i++) {
            targetContract[i] = mirrorToken[destChainId[i]];
        }

        bytes1[] memory mode = new bytes1[](dataLength);
        for (uint256 i = 0; i < dataLength; i++) {
            mode[i] = defaultBridgeMode;
        }

        uint24[] memory gasLimit = new uint24[](dataLength);
        for (uint256 i = 0; i < dataLength; i++) {
            gasLimit[i] = minGasLimit;
        }

        return (message, targetContract, mode, gasLimit);
    }

    function emit2LaunchPad(
        IMessageStruct.launchMultiMsgParams memory params
    ) public payable virtual {
        LaunchPad.Launch{value: msg.value}(params);
    }

    function emit2LaunchPad(
        IMessageStruct.launchSingleMsgParams memory params
    ) public payable virtual {
        LaunchPad.Launch{value: msg.value}(params);
    }

    function converActivateRawMsg(
        activateRawMsg memory rawMsg
    ) public pure virtual returns (IMessageStruct.launchMultiMsgParams memory) {
        return
            IMessageStruct.launchMultiMsgParams(
                rawMsg.earlistArrivalTimestamp,
                rawMsg.latestArrivalTimestamp,
                rawMsg.relayer,
                rawMsg.sender,
                new uint256[](0),
                rawMsg.destChainld,
                rawMsg.aditionParams,
                PacketMessages(
                    rawMsg.mode,
                    rawMsg.gasLimit,
                    rawMsg.targetContarct,
                    rawMsg.message
                )
            );
    }

    /// @dev bellow are the virtual functions, feel free to override them in your own contract.
    /// for Example, you can override the _tokenHandlingStrategy,
    /// instead of burning the token, you can transfer the token to a specific address.
    function _tokenHandlingStrategy(uint256 amount) internal virtual {
        _burn(msg.sender, amount);
    }

    /// @dev we override this function because mint() method implements permission checking for the landing pad,
    ///         so it can be called here.
    function _fetchSignature(
        address toAddress,
        uint256 amount
    ) internal view virtual returns (bytes memory signature) {
        signature = abi.encodeCall(IOmniTokenCore.mint, (toAddress, amount));
    }

    function _receiveMessage(
        uint64 srcChainId,
        uint32 nonce,
        address sender,
        bytes calldata message
    ) internal virtual override {
        (srcChainId, nonce, sender);
        // decode the message, args is for mint(address toAddress, uint256 amount)
        (address toAddress, uint256 amount) = abi.decode(
            message,
            (address, uint256)
        );
        mint(toAddress, amount);
    }
}
