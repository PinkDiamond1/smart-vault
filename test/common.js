const { ethers } = require('hardhat');

const HUNDRED_PC = 100000;
const DEFAULT_COLLATERAL_RATE = 120000; // 120%
const DEFAULT_ETH_USD_PRICE = 125000000000; // $1250
const DEFAULT_EUR_USD_PRICE = 105000000; // $1.05
const PROTOCOL_FEE_RATE = 1000; // 1%

const getCollateralOf = (symbol, collateral) => collateral.filter(c => c.symbol === ethers.utils.formatBytes32String(symbol))[0];

module.exports = {
  HUNDRED_PC,
  DEFAULT_COLLATERAL_RATE,
  DEFAULT_ETH_USD_PRICE,
  DEFAULT_EUR_USD_PRICE,
  PROTOCOL_FEE_RATE,
  getCollateralOf
}