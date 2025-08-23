// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title Auction 拍卖合约
 * @dev 实现了NFT拍卖功能，支持ETH和ERC20代币出价，使用Chainlink预言机计算美元价值
 *      并实现动态手续费机制
 */
contract Auction is ReentrancyGuard, Ownable {
    // 拍卖信息结构
    struct AuctionInfo {
        address nftContract;     // NFT合约地址
        uint256 tokenId;         // NFT代币ID
        address payable seller;  // 卖家地址
        uint256 startTime;       // 拍卖开始时间
        uint256 endTime;         // 拍卖结束时间
        bool ended;              // 拍卖是否已结束
    }

    // 出价信息结构
    struct BidInfo {
        address bidder;    // 出价者地址
        uint256 bidAmount; // 出价金额
        address token;     // 代币地址 (address(0) 表示 ETH)
        uint256 timestamp; // 出价时间戳
    }

    // 拍卖变量
    AuctionInfo public auction;  // 拍卖信息
    BidInfo[] public bids;       // 所有出价记录
    
    // Chainlink 价格预言机
    AggregatorV3Interface public ethPriceFeed;                  // ETH/USD价格预言机
    mapping(address => AggregatorV3Interface) public tokenPriceFeeds;  // ERC20代币价格预言机映射
    
    // 手续费相关
    uint256 public feePercentage; // 手续费百分比 (以基点表示，100基点=1%，1000基点=10%)
    address public feeRecipient;  // 手续费接收者地址
    
    // 事件
    event AuctionCreated(address indexed nftContract, uint256 indexed tokenId, uint256 endTime);
    event BidPlaced(address indexed bidder, uint256 amount, address token);
    event AuctionEnded(address indexed winner, uint256 amount, address token);
    event FeeSettingsUpdated(uint256 feePercentage, address feeRecipient);
    event FeePaid(address token, uint256 amount);
    
    /**
     * @dev 构造函数，初始化拍卖合约
     * @param _nftContract NFT合约地址
     * @param _tokenId NFT代币ID
     * @param _startingPrice 起拍价（未使用，仅作参考）
     * @param _duration 拍卖持续时间（秒）
     * @param _ethPriceFeed ETH/USD价格预言机地址
     * @param _owner 合约所有者地址
     * @param _feePercentage 手续费百分比（基点）
     * @param _feeRecipient 手续费接收者地址
     */
    constructor(
        address _nftContract,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _duration,
        address _ethPriceFeed,
        address _owner,
        uint256 _feePercentage,
        address _feeRecipient
    ) Ownable(_owner) {
        auction = AuctionInfo({
            nftContract: _nftContract,
            tokenId: _tokenId,
            seller: payable(msg.sender),
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            ended: false
        });
        
        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);
        
        // 设置手续费参数
        feePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
        
        // 转移NFT到合约
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);
        
        emit AuctionCreated(_nftContract, _tokenId, auction.endTime);
    }
    
    // 设置手续费参数 (仅限所有者)
    function setFeeSettings(uint256 _feePercentage, address _feeRecipient) external onlyOwner {
        require(_feePercentage <= 1000, "Fee percentage cannot exceed 10%"); // 最高10%
        feePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
        emit FeeSettingsUpdated(_feePercentage, _feeRecipient);
    }
    
    // 设置ERC20代币价格预言机
    function setTokenPriceFeed(address token, address priceFeed) external onlyOwner {
        tokenPriceFeeds[token] = AggregatorV3Interface(priceFeed);
    }
    
    // 获取ETH价格（以美元为单位）
    function getETHPrice() public view returns (uint256) {
        (, int256 price, , , ) = ethPriceFeed.latestRoundData();
        return uint256(price);
    }
    
    // 获取代币价格（以美元为单位）
    function getTokenPrice(address token) public view returns (uint256) {
        AggregatorV3Interface priceFeed = tokenPriceFeeds[token];
        require(address(priceFeed) != address(0), "Price feed not set for token");
        
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }
    
    // 出价函数（ETH）
    function bid() external payable nonReentrant {
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(!auction.ended, "Auction has ended");
        require(msg.sender != auction.seller, "Seller cannot bid");
        
        require(msg.value > 0, "Bid amount must be greater than 0");
        
        // 如果有之前的出价，退还
        for (uint i = 0; i < bids.length; i++) {
            if (bids[i].bidder == msg.sender && bids[i].token == address(0)) {
                payable(msg.sender).transfer(bids[i].bidAmount);
                bids[i] = bids[bids.length - 1];
                bids.pop();
                break;
            }
        }
        
        bids.push(BidInfo({
            bidder: msg.sender,
            bidAmount: msg.value,
            token: address(0),
            timestamp: block.timestamp
        }));
        
        emit BidPlaced(msg.sender, msg.value, address(0));
    }
    
    // 出价函数（ERC20）
    function bidWithToken(address token, uint256 amount) external nonReentrant {
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(!auction.ended, "Auction has ended");
        require(msg.sender != auction.seller, "Seller cannot bid");
        require(amount > 0, "Bid amount must be greater than 0");
        require(address(tokenPriceFeeds[token]) != address(0), "Token price feed not set");
        
        // 转移代币到合约
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        // 如果有之前的出价，退还
        for (uint i = 0; i < bids.length; i++) {
            if (bids[i].bidder == msg.sender && bids[i].token == token) {
                IERC20(token).transfer(msg.sender, bids[i].bidAmount);
                bids[i] = bids[bids.length - 1];
                bids.pop();
                break;
            }
        }
        
        bids.push(BidInfo({
            bidder: msg.sender,
            bidAmount: amount,
            token: token,
            timestamp: block.timestamp
        }));
        
        emit BidPlaced(msg.sender, amount, token);
    }
    
    // 计算手续费
    function calculateFee(uint256 amount) public view returns (uint256) {
        return (amount * feePercentage) / 10000; // 10000基点 = 100%
    }
    
    // 结束拍卖
    function endAuction() external nonReentrant {
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");
        require(!auction.ended, "Auction has already ended");
        
        auction.ended = true;
        
        if (bids.length == 0) {
            // 没有出价，将NFT退还给卖家
            IERC721(auction.nftContract).transferFrom(address(this), auction.seller, auction.tokenId);
            emit AuctionEnded(address(0), 0, address(0));
            return;
        }
        
        // 找到最高出价
        BidInfo memory highestBid = bids[0];
        for (uint i = 1; i < bids.length; i++) {
            uint256 currentUSDValue = getUSDValue(highestBid.token, highestBid.bidAmount);
            uint256 newBidUSDValue = getUSDValue(bids[i].token, bids[i].bidAmount);
            
            if (newBidUSDValue > currentUSDValue) {
                highestBid = bids[i];
            }
        }
        
        // 计算手续费和卖家应得金额
        uint256 feeAmount = calculateFee(highestBid.bidAmount);
        uint256 sellerAmount = highestBid.bidAmount - feeAmount;
        
        // 将NFT转移给出价最高者
        IERC721(auction.nftContract).transferFrom(address(this), highestBid.bidder, auction.tokenId);
        
        // 支付手续费
        if (feeAmount > 0) {
            if (highestBid.token == address(0)) {
                payable(feeRecipient).transfer(feeAmount);
            } else {
                IERC20(highestBid.token).transfer(feeRecipient, feeAmount);
            }
            emit FeePaid(highestBid.token, feeAmount);
        }
        
        // 将资金转移给卖家
        if (sellerAmount > 0) {
            if (highestBid.token == address(0)) {
                auction.seller.transfer(sellerAmount);
            } else {
                IERC20(highestBid.token).transfer(auction.seller, sellerAmount);
            }
        }
        
        // 退还其他出价者的资金
        for (uint i = 0; i < bids.length; i++) {
            if (bids[i].bidder != highestBid.bidder) {
                if (bids[i].token == address(0)) {
                    payable(bids[i].bidder).transfer(bids[i].bidAmount);
                } else {
                    IERC20(bids[i].token).transfer(bids[i].bidder, bids[i].bidAmount);
                }
            }
        }
        
        emit AuctionEnded(highestBid.bidder, highestBid.bidAmount, highestBid.token);
    }
    
    // 获取出价的美元价值
    function getUSDValue(address token, uint256 amount) public view returns (uint256) {
        if (token == address(0)) {
            // ETH
            uint256 ethPrice = getETHPrice();
            return (amount * ethPrice) / 1e18; // ETH价格通常有18位小数，价格本身有8位小数
        } else {
            // ERC20 token
            uint256 tokenPrice = getTokenPrice(token);
            return (amount * tokenPrice) / 1e18; // 假设token价格有8位小数
        }
    }
    
    // 查看当前最高出价
    function getCurrentHighestBid() external view returns (address bidder, uint256 amount, address token) {
        if (bids.length == 0) {
            return (address(0), 0, address(0));
        }
        
        BidInfo memory highestBid = bids[0];
        for (uint i = 1; i < bids.length; i++) {
            uint256 currentUSDValue = getUSDValue(highestBid.token, highestBid.bidAmount);
            uint256 newBidUSDValue = getUSDValue(bids[i].token, bids[i].bidAmount);
            
            if (newBidUSDValue > currentUSDValue) {
                highestBid = bids[i];
            }
        }
        
        return (highestBid.bidder, highestBid.bidAmount, highestBid.token);
    }
}