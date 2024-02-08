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
        uint256 amount
    ) external payable override {
        _tokenHandlingStrategy(amount);
        bridgeTransferHandler(destChainId, receiver, amount);
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
        // gasLimit[0] = MINIMAL_GAS_LIMIT;
        // emit2LaunchPad(
        //     IMessageSpaceStation.launchMultiMsgParams(
        //         destChainIdArr,
        //         uint64(block.timestamp + OMINI_MINIMAL_ARRIVAL_TIME),
        //         uint64(block.timestamp + OMINI_MAXIMAL_ARRIVAL_TIME),
        //         msg.sender,
        //         DEFAULT_RELAYER,
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
        // message[0] = _fetchSignature(receiver, amount);

        // address[] memory targetContract = new address[](1);
        // targetContract[0] = mirrorToken[destChainId];

        // bytes1[] memory mode = new bytes1[](1);
        // mode[0] = MessageTypeLib.ARBITRARY_ACTIVATE;

        // uint24[] memory gasLimit = new uint24[](1);
        // gasLimit[0] = MINIMAL_GAS_LIMIT;

        LaunchPad.Launch{value: msg.value}(
            IMessageSpaceStation.launchSingleMsgParams(
                destChainId,
                uint64(block.timestamp + OMINI_MINIMAL_ARRIVAL_TIME),
                uint64(block.timestamp + OMINI_MAXIMAL_ARRIVAL_TIME),
                msg.sender,
                DEFAULT_RELAYER,
                new bytes(0),
                abi.encodePacked(
                    MessageTypeLib.ARBITRARY_ACTIVATE,
                    uint256(uint160(mirrorToken[destChainId])),
                    MAXIMAL_GAS_LIMIT,
                    _fetchSignature(receiver, amount)
                )
            )
        );
    }

    /// @notice before you bridgeTransfer, please call this function to get the bridge fee
    /// @dev if your token would charge a extra fee, you can override this function
    /// @return the fee of the bridge transfer
    function fetchOminiTokenTransferFee(
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
            LaunchPad.FetchProtocolFee(
                IMessageSpaceStation.launchMultiMsgParams(
                    destChainId,
                    uint64(block.timestamp + OMINI_MINIMAL_ARRIVAL_TIME),
                    uint64(block.timestamp + OMINI_MAXIMAL_ARRIVAL_TIME),
                    msg.sender,
                    DEFAULT_RELAYER,
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
            mode[i] = DEFAULT_MODE;
        }

        uint24[] memory gasLimit = new uint24[](dataLength);
        for (uint256 i = 0; i < dataLength; i++) {
            gasLimit[i] = MINIMAL_GAS_LIMIT;
        }

        return (message, targetContract, mode, gasLimit);
    }
}
