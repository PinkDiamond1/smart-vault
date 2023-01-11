// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/interfaces/IChainlink.sol";
import "contracts/SmartVault.sol";
import "contracts/interfaces/ITokenManager.sol";

contract SmartVaultManager is ERC721, Ownable {
    uint256 public constant hundredPC = 100000;

    address public protocol;
    address public seuro;
    uint256 public collateralRate;
    uint256 public feeRate;
    IChainlink public clEthUsd;
    IChainlink public clEurUsd;
    ITokenManager public tokenManager;
    mapping(address => uint256[]) public tokenIds;
    mapping(uint256 => address payable) public vaultAddresses;

    uint256 private currentToken;

    struct SmartVaultData { uint256 tokenId; address vaultAddress; uint256 collateralRate; uint256 feeRate; SmartVault.Status status; }

    constructor(uint256 _collateralRate, uint256 _feeRate, address _seuro, address _clEthUsd, address _clEurUsd, address _protocol, address _tokenManager) ERC721("The Standard Smart Vault Manager", "TSVAULTMAN") {
        collateralRate = _collateralRate;
        clEthUsd = IChainlink(_clEthUsd);
        clEurUsd = IChainlink(_clEurUsd);
        seuro = _seuro;
        feeRate = _feeRate;
        protocol = _protocol;
        tokenManager = ITokenManager(_tokenManager);
    }

    modifier onlyVaultOwner(uint256 _tokenId) {
        require(msg.sender == ownerOf(_tokenId), "err-not-owner");
        _;
    }

    function getVault(uint256 _tokenId) private view returns (SmartVault) {
        return SmartVault(vaultAddresses[_tokenId]);
    }

    function vaults() external view returns (SmartVaultData[] memory) {
        uint256[] memory userTokens = tokenIds[msg.sender];
        SmartVaultData[] memory vaultData = new SmartVaultData[](userTokens.length);
        for (uint256 i = 0; i < userTokens.length; i++) {
            uint256 tokenId = userTokens[i];
            vaultData[i] = SmartVaultData({
                tokenId: tokenId,
                vaultAddress: vaultAddresses[tokenId],
                collateralRate: collateralRate,
                feeRate: feeRate,
                status: getVault(tokenId).status()
            });
        }
        return vaultData;
    }

    function mint() external returns (address vault, uint256 tokenId) {
        SmartVault smartVault = new SmartVault(address(this), msg.sender, seuro);
        vault = address(smartVault);
        tokenId = ++currentToken;
        vaultAddresses[tokenId] = payable(vault);
        _mint(msg.sender, tokenId);
        // TODO give minter rights to new vault (manager will have to be minter admin)
    }

    function addCollateralETH(uint256 _tokenId) external payable onlyVaultOwner(_tokenId) {
        (bool sent,) = vaultAddresses[_tokenId].call{value: msg.value}("");
        require(sent, "err-send-eth");
    }

    function mintSEuro(uint256 _tokenId, address _to, uint256 _amount) external onlyVaultOwner(_tokenId) {
        getVault(_tokenId).mint(_to, _amount);
    }

    function removeTokenId(address _user, uint256 _tokenId) private {
        uint256[] memory currentIds = tokenIds[_user];
        delete tokenIds[_user];
        for (uint256 i = 0; i < currentIds.length; i++) {
            if (currentIds[i] != _tokenId) tokenIds[_user].push(currentIds[i]);
        }
    }

    function _afterTokenTransfer(address _from, address _to, uint256 _tokenId, uint256) internal override {
        removeTokenId(_from, _tokenId);
        tokenIds[_to].push(_tokenId);
        if (address(_from) != address(0)) SmartVault(vaultAddresses[_tokenId]).setOwner(_to);
    }

    function setTokenManager(address _tokenManager) external onlyOwner {
        require(_tokenManager != address(tokenManager) && _tokenManager != address(0), "err-invalid-address");
        tokenManager = ITokenManager(_tokenManager);
    }
}
