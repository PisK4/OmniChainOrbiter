// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IOtherChainInterface {
    function mint(uint256 amount) external;
}

contract chainA_EncodeMessageDemo {
    bytes public storeMessage;

    function bridgeSignatureMessage(
        uint256 amount
    ) external view returns (bytes memory) {
        bytes memory message = abi.encodeWithSignature(
            "mint(address,uint256)",
            msg.sender,
            amount
        );
        return message;
    }

    function bridgeSignatureMessage2(
        uint256 amount
    ) external pure returns (bytes memory) {
        bytes memory message = abi.encodeWithSignature("mint(uint256)", amount);
        // storeMessage = message;
        return message;
    }

    function bridgeSignatureMessage3(
        uint256 amount
    ) external pure returns (bytes memory) {
        bytes memory message = abi.encodeCall(
            IOtherChainInterface.mint,
            (amount)
        );
        return message;
    }

    function buildMessage(
        bytes1 mode,
        address toAddress,
        uint24 gasLimit,
        uint256 args
    ) external view returns (bytes memory) {
        uint256 contractAddr = uint256(uint160(toAddress));
        bytes memory signature = abi.encodePacked(
            mode,
            contractAddr,
            gasLimit,
            abi.encodeWithSignature("mint(address,uint256)", msg.sender, args)
        );
        return signature;
    }

    function excuteMessage(
        address contractAddr,
        bytes calldata message
    ) external {
        (bool success, ) = contractAddr.call{gas: 1000000}(message);
        require(success, "excute error");
    }
}

struct XChainMessage {
    uint8 launchVesion;
    address from;
    address to;
    uint64 sourceID;
    uint64 destID;
    uint256 earlistArrivalTime;
    uint256 latestArrivalTime;
    address sendAddress;
    address receiveAddress;
    uint256 tokenAddress;
    uint256 tokenAmount;
    uint256 relayerNode;
    uint24 extralGasLimit;
    uint24 excuteGasLimit;
    bytes message;
}

library relayerMessage {
    // function decode(bytes calldata _message) public view returns(XChainMessage memory){
    //     XChainMessage memory decodedMessage = XChainMessage({
    //         from: msg.sender,
    //         to: msg.sender,
    //         message: _message
    //     });
    //     return decodedMessage;
    // }
}

contract chainB_RouterContract {
    function relayMessage(bytes calldata message) public pure returns (bytes1) {
        bytes1 messageSlice = bytes1(message[0:1]);
        return messageSlice;
    }

    // function excuteMessage(bytes message)
}
