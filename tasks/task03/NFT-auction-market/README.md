# NFT 拍卖市场

本项目实现了一个完整的 NFT 拍卖市场，具有以下功能：

## 功能特点

1. **NFT 合约**：实现 ERC721 标准用于创建和管理 NFT
2. **拍卖合约**：处理拍卖功能，包括出价和结束拍卖
3. **拍卖工厂**：使用工厂模式（类似于 Uniswap V2）创建和管理拍卖合约
4. **Chainlink 集成**：使用 Chainlink 价格预言机计算出价的美元价值
5. **可升级合约**：实现 UUPS 和透明代理模式以支持合约升级
6. **跨链拍卖**：设计支持使用 Chainlink CCIP 的跨链拍卖（待实现）
7. **动态手续费**：根据拍卖金额动态计算并收取手续费

## 合约

- `NFT.sol`：基于 ERC721 的 NFT 合约
- `Auction.sol`：处理出价和拍卖逻辑的主拍卖合约
- `AuctionFactory.sol`：用于创建新拍卖的工厂合约
- `UUPSAuctionFactory.sol`：使用 UUPS 模式的可升级工厂
- `TransparentAuctionFactory.sol`：使用透明代理模式的可升级工厂

## 入门指南

### 先决条件

- Node.js >= 16.0.0
- Hardhat

### 安装

```shell
npm install
```

### 编译合约

```shell
npx hardhat compile
```

### 运行测试

```shell
npx hardhat test
```

### 部署合约

```shell
npx hardhat ignition deploy ./ignition/modules/AuctionModule.js
```

对于 UUPS 可升级版本：
```shell
npx hardhat ignition deploy ./ignition/modules/UUPSAuctionModule.js
```

## 架构设计

### 工厂模式

该项目使用类似于 Uniswap V2 的工厂模式来创建和管理单独的拍卖合约。每个拍卖都作为独立合约部署，这提供了：

1. 拍卖之间的隔离
2. 单个拍卖合约中更简单的逻辑
3. 复杂操作更好的 gas 效率

### Chainlink 集成

Chainlink 价格预言机用于：
1. 获取 ETH/USD 价格
2. 获取 ERC20 代币/USD 价格
3. 计算出价的美元价值以进行公平比较

### 动态手续费

本项目实现了动态手续费功能：
1. 手续费根据拍卖最终成交金额的百分比计算
2. 默认手续费率为1%，最高可设置为10%
3. 手续费在拍卖结束时自动从成交金额中扣除
4. 手续费接收者可以是任意指定地址

### 可升级性

该项目实现了两种类型的可升级合约：
1. **UUPS（通用可升级代理标准）**：gas 效率更高
2. **透明代理**：更成熟的模式

两种模式都允许升级工厂合约逻辑同时保留状态。

## 安全考虑

- 使用 OpenZeppelin 的 ReentrancyGuard 防止重入攻击
- 使用 OpenZeppelin 的 Ownable 进行访问控制
- 对输入和边界情况进行适当验证
- 使用经过良好审计的库中的成熟模式

## 未来改进

1. 使用 Chainlink CCIP 添加跨链拍卖支持
2. 为市场创建前端界面
3. 添加更广泛的测试覆盖