// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// Chainlink ETH/USD Price Feed addresses (Sepolia testnet)
// 参考: https://docs.chain.link/data-feeds/price-feeds/addresses
const ETH_PRICE_FEED_SEPOLIA = "0x694AA1769357215DE4FAC081bf1f309aDC325306";

export default buildModule("AuctionModule", (m) => {
  // 获取部署者地址
  const owner = m.getAccount(0);
  
  // 设置手续费参数 (1% = 100基点)
  const feePercentage = 100;
  const feeRecipient = owner;

  // 部署NFT合约
  const nft = m.contract("NFT", []);

  // 部署工厂合约
  const factory = m.contract("AuctionFactory", [ETH_PRICE_FEED_SEPOLIA, owner, feePercentage, feeRecipient]);

  return { nft, factory };
});