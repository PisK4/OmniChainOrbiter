// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IVizingNFTStation {
    function warpNFT(address token, uint256 _tokenId) external;

    function unwarpNFT(uint256 _tokenId) external;

    function mintNFT(address _to, uint256 _tokenId) external;

    function burnNFT(uint256 _tokenId) external;

    function transferNFT(
        uint24 _chainId,
        address _to,
        uint256 _tokenId
    ) external;

    function warpTransferNFT(
        uint24 _chainId,
        address _to,
        address token,
        uint256 _tokenId
    ) external;

    function calculateWarpNFTtokenId(
        address token,
        uint256 _tokenId
    ) external view returns (uint256);
}
