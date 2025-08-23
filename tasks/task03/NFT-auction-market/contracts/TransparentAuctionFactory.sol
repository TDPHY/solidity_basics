// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Auction.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title TransparentAuctionFactory 透明代理拍卖工厂合约
 * @dev 使用透明代理模式实现的可升级拍卖工厂合约
 *      透明代理模式是一种成熟的可升级模式，允许在保持状态的同时升级合约逻辑
 */
contract TransparentAuctionFactory is Initializable, OwnableUpgradeable {
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
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /**
     * @dev 初始化函数，替代构造函数用于可升级合约
     * @param _ethPriceFeed ETH/USD价格预言机地址
     * @param initialOwner 合约初始所有者地址
     * @param _feePercentage 手续费百分比（基点）
     * @param _feeRecipient 手续费接收者地址
     */
    function initialize(
        address _ethPriceFeed, 
        address initialOwner,
        uint256 _feePercentage,
        address _feeRecipient
    ) initializer public {
        __Ownable_init(initialOwner);
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