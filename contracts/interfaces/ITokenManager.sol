// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ITokenManager {
    struct Token { bytes32 symbol; address addr; uint8 dec; address clAddr; uint8 clDec; }

    function clEurUsd() external view returns (address);

    function getAcceptedTokens() external view returns (Token[] memory);

    function getAddressOf(bytes32 _symbol) external view returns (address);
}