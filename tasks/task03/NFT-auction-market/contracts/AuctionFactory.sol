// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Auction.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AuctionFactory 拍卖工厂合约
 * @dev 工厂模式合约，用于创建和管理多个拍卖合约实例
 *      使用工厂模式可以为每个拍卖创建独立的合约实例，提供更好的隔离性和gas效率
 */
contract AuctionFactory is Ownable {
    // 存储所有创建的拍卖
    address[] public auctions;
    
    // Chainlink ETH/USD 价格预言机地址
    address public ethPriceFeed;
    
    // 手续费相关
    uint256 public feePercentage; // 手续费百分比 (以基点表示，100基点=1%)
    address public feeRecipient;  // 手续费接收者
    
    // 事件
    event AuctionCreated(address indexed auction, address indexed nftContract, uint256 indexed tokenId);
    event NewPriceFeedSet(address indexed token, address indexed priceFeed);
    event FeeSettingsUpdated(uint256 feePercentage, address feeRecipient);
    
    // 价格预言机映射
    mapping(address => address) public tokenPriceFeeds;
    
    /**
     * @dev 构造函数，初始化拍卖工厂合约
     * @param _ethPriceFeed ETH/USD价格预言机地址
     * @param initialOwner 合约初始所有者地址
     * @param _feePercentage 手续费百分比（基点）
     * @param _feeRecipient 手续费接收者地址
     */
    constructor(
        address _ethPriceFeed, 
        address initialOwner,
        uint256 _feePercentage,
        address _feeRecipient
    ) Ownable(initialOwner) {
        ethPriceFeed = _ethPriceFeed;
        feePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
    }
    
    // 设置手续费参数 (仅限所有者)
    function setFeeSettings(uint256 _feePercentage, address _feeRecipient) external onlyOwner {
        require(_feePercentage <= 1000, "Fee percentage cannot exceed 10%"); // 最高10%
        feePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
        emit FeeSettingsUpdated(_feePercentage, _feeRecipient);
    }
    
    /**
     * @dev 创建新的拍卖合约实例
     * @param _nftContract NFT合约地址
     * @param _tokenId NFT代币ID
     * @param _startingPrice 起拍价（仅作参考）
     * @param _duration 拍卖持续时间（秒）
     * @return 新创建的拍卖合约地址
     */
    function createAuction(
        address _nftContract,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _duration
    ) external returns (address) {
        Auction newAuction = new Auction(
            _nftContract,
            _tokenId,
            _startingPrice,
            _duration,
            ethPriceFeed,
            msg.sender,
            feePercentage,
            feeRecipient
        );
        
        // 将新拍卖添加到列表
        auctions.push(address(newAuction));
        
        // 将工厂设置为拍卖的所有者，以便可以设置价格预言机
        newAuction.transferOwnership(msg.sender);
        
        emit AuctionCreated(address(newAuction), _nftContract, _tokenId);
        
        return address(newAuction);
    }
    
    // 设置ERC20代币价格预言机
    function setTokenPriceFeed(address token, address priceFeed) external onlyOwner {
        tokenPriceFeeds[token] = priceFeed;
        emit NewPriceFeedSet(token, priceFeed);
    }
    
    // 获取所有拍卖列表
    function getAuctions() external view returns (address[] memory) {
        return auctions;
    }
    
    // 获取拍卖数量
    function getAuctionsCount() external view returns (uint256) {
        return auctions.length;
    }
}