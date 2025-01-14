// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IChainlink {
    function decimals() external view returns (uint8);
    function getRoundData(uint80 _roundId) external view 
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function latestRoundData() external view 
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}