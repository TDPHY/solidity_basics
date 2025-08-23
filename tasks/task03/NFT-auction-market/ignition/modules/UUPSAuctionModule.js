// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";

// Chainlink ETH/USD Price Feed addresses (Sepolia testnet)
// 参考: https://docs.chain.link/data-feeds/price-feeds/addresses
const ETH_PRICE_FEED_SEPOLIA = "0x694AA1769357215DE4FAC081bf1f309aDC325306";

export default buildModule("UUPSAuctionModule", (m) => {
  // 获取部署者地址
  const owner = m.getAccount(0);
  
  // 设置手续费参数 (1% = 100基点)
  const feePercentage = 100;
  const feeRecipient = owner;

  // 部署UUPS工厂实现合约
  const implementation = m.contract("UUPSAuctionFactory");

  // 准备初始化数据
  const initializeData = ethers.concat([
    implementation.interface.encodeFunctionData("initialize", [ETH_PRICE_FEED_SEPOLIA, owner, feePercentage, feeRecipient])
  ]);

  // 部署代理合约并初始化
  const proxy = m.contract("ERC1967Proxy", [
    implementation,
    initializeData
  ]);

  return { implementation, proxy };
});