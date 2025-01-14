// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/interfaces/IChainlink.sol";
import "contracts/interfaces/ITokenManager.sol";

contract TokenManager is ITokenManager, Ownable {
    bytes32 private immutable NATIVE;

    Token[] private acceptedTokens;
    address public clNativeUsd;

    constructor(bytes32 _native, address _clNativeUsd) {
        NATIVE = _native;
        clNativeUsd = _clNativeUsd;
        acceptedTokens.push(Token(NATIVE, address(0), 18, _clNativeUsd, IChainlink(clNativeUsd).decimals()));
    }

    function getAcceptedTokens() external view returns (Token[] memory) {
        return acceptedTokens;
    }

    function getToken(bytes32 _symbol) external view returns (Token memory token) {
        for (uint256 i = 0; i < acceptedTokens.length; i++) if (acceptedTokens[i].symbol == _symbol) token = acceptedTokens[i];
        require(token.symbol == _symbol, "err-invalid-token");
    }

    function getTokenIfExists(address _tokenAddr) external view returns (Token memory token) {
        for (uint256 i = 0; i < acceptedTokens.length; i++) if (acceptedTokens[i].addr == _tokenAddr) token = acceptedTokens[i];
    }

    function addAcceptedToken(address _token, address _chainlinkFeed) external onlyOwner {
        ERC20 token = ERC20(_token);
        bytes32 symbol = bytes32(bytes(token.symbol()));
        for (uint256 i = 0; i < acceptedTokens.length; i++) if (acceptedTokens[i].symbol == symbol) revert("err-token-exists");
        IChainlink dataFeed = IChainlink(_chainlinkFeed);
        acceptedTokens.push(Token(symbol, _token, token.decimals(), _chainlinkFeed, dataFeed.decimals()));
    }

    function removeAcceptedToken(bytes32 _symbol) external onlyOwner {
        require(_symbol != NATIVE);
        for (uint256 i = 0; i < acceptedTokens.length; i++) {
            if (acceptedTokens[i].symbol == _symbol) {
                acceptedTokens[i] = acceptedTokens[acceptedTokens.length - 1];
                acceptedTokens.pop();
            }
        }
    }
}
