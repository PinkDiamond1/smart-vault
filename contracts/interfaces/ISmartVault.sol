// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ISmartVault {
    struct Asset { bytes32 symbol; uint256 amount; }
    struct Status { 
        uint256 minted; uint256 maxMintable; uint256 currentCollateralPercentage;
        Asset[] collateral; bool liquidated; uint8 version; bytes32 vaultType;
    }

    function status() external view returns (Status memory);
    function undercollateralised() external view returns (bool);
    function setOwner(address _newOwner) external;
    function liquidate() external;
}