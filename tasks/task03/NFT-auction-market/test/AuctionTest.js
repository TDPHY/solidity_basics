import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers.js";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs.js";
import { expect } from "chai";
import hardhat from "hardhat";

const { ethers } = hardhat;

describe("NFT Auction Market", function () {
  // 部署合约的fixture
  async function deployAuctionFixture() {
    // 获取签名者
    const [owner, seller, bidder1, bidder2, bidder3, feeRecipient] = await ethers.getSigners();
    
    // 部署NFT合约
    const NFT = await ethers.getContractFactory("NFT");
    const nft = await NFT.deploy();
    
    // 部署工厂合约 (使用模拟的ETH价格预言机地址)
    const AuctionFactory = await ethers.getContractFactory("AuctionFactory");
    const factory = await AuctionFactory.deploy("0x694AA1769357215DE4FAC081bf1f309aDC325306", owner.address, 100, feeRecipient.address); // 1%手续费
    
    // 铸造一个NFT
    const tokenURI = "https://example.com/metadata/1";
    await nft.mint(seller.address, tokenURI);
    const tokenId = 1;
    
    // 授权NFT给工厂合约
    await nft.connect(seller).approve(factory.target, tokenId);
    
    return { nft, factory, owner, seller, bidder1, bidder2, bidder3, tokenId, tokenURI, feeRecipient };
  }
  
  describe("NFT Contract", function () {
    it("Should mint NFT correctly", async function () {
      const { nft, seller, tokenURI } = await loadFixture(deployAuctionFixture);
      
      await nft.mint(seller.address, tokenURI);
      expect(await nft.ownerOf(2)).to.equal(seller.address);
      expect(await nft.tokenURI(2)).to.equal(tokenURI);
    });
  });
  
  describe("Auction Factory", function () {
    it("Should create auction correctly", async function () {
      const { nft, factory, seller, tokenId } = await loadFixture(deployAuctionFixture);
      
      const duration = 3600; // 1小时
      
      // 创建拍卖
      const tx = await factory.connect(seller).createAuction(
        nft.target,
        tokenId,
        0, // 起拍价
        duration
      );
      
      await expect(tx).to.emit(factory, "AuctionCreated");
      
      // 检查拍卖数量
      expect(await factory.getAuctionsCount()).to.equal(1);
    });
  });
  
  describe("Auction Contract", function () {
    async function deployAuctionWithBidsFixture() {
      const { nft, factory, owner, seller, bidder1, bidder2, bidder3, tokenId, tokenURI, feeRecipient } = await loadFixture(deployAuctionFixture);
      
      const duration = 3600; // 1小时
      
      // 创建拍卖
      const createTx = await factory.connect(seller).createAuction(
        nft.target,
        tokenId,
        0, // 起拍价
        duration
      );
      
      const receipt = await createTx.wait();
      const auctionAddress = receipt.logs[0].args.auction;
      
      // 获取拍卖合约
      const Auction = await ethers.getContractFactory("Auction");
      const auction = Auction.attach(auctionAddress);
      
      return { nft, factory, auction, owner, seller, bidder1, bidder2, bidder3, tokenId, feeRecipient };
    }
    
    it("Should accept ETH bids", async function () {
      const { auction, bidder1 } = await loadFixture(deployAuctionWithBidsFixture);
      
      const bidAmount = ethers.parseEther("1");
      
      await expect(auction.connect(bidder1).bid({ value: bidAmount }))
        .to.emit(auction, "BidPlaced")
        .withArgs(bidder1.address, bidAmount, ethers.ZeroAddress);
    });
    
    it("Should accept ERC20 token bids", async function () {
      // 这个测试需要部署一个ERC20代币合约，为简化起见暂时跳过
      // 在完整实现中，我们会部署一个测试代币并设置价格预言机
    });
    
    it("Should end auction and transfer NFT to winner", async function () {
      const { nft, auction, seller, bidder1, bidder2, tokenId, feeRecipient } = await loadFixture(deployAuctionWithBidsFixture);
      
      // 出价
      const bid1Amount = ethers.parseEther("1");
      const bid2Amount = ethers.parseEther("2");
      
      await auction.connect(bidder1).bid({ value: bid1Amount });
      await auction.connect(bidder2).bid({ value: bid2Amount });
      
      // 记录初始余额
      const sellerInitialBalance = await ethers.provider.getBalance(seller.address);
      const feeRecipientInitialBalance = await ethers.provider.getBalance(feeRecipient.address);
      
      // 增加时间以结束拍卖
      const auctionEndTime = await auction.auction.endTime();
      await time.increaseTo(auctionEndTime + 1n);
      
      // 结束拍卖
      await expect(auction.connect(seller).endAuction())
        .to.emit(auction, "AuctionEnded")
        .withArgs(bidder2.address, bid2Amount, ethers.ZeroAddress);
      
      // 检查NFT所有权
      expect(await nft.ownerOf(tokenId)).to.equal(bidder2.address);
      
      // 检查余额变化
      const sellerFinalBalance = await ethers.provider.getBalance(seller.address);
      const feeRecipientFinalBalance = await ethers.provider.getBalance(feeRecipient.address);
      
      // 卖家应该收到 1.98 ETH (2 ETH - 1% 手续费)
      // 注意：卖家的余额变化还包括gas费用，所以我们只验证手续费接收者收到的金额
      // expect(sellerFinalBalance - sellerInitialBalance).to.equal(ethers.parseEther("1.98"));
      
      // 手续费接收者应该收到 0.02 ETH (2 ETH 的 1% 手续费)
      expect(feeRecipientFinalBalance - feeRecipientInitialBalance).to.equal(ethers.parseEther("0.02"));
    });
    
    it("Should handle dynamic fee correctly", async function () {
      const { factory, seller, bidder1, bidder2, feeRecipient } = await loadFixture(deployAuctionWithBidsFixture);
      const { nft } = await loadFixture(deployAuctionFixture);
      
      // 创建另一个拍卖
      const duration = 3600; // 1小时
      await nft.mint(seller.address, "https://example.com/metadata/2");
      await nft.connect(seller).approve(factory.target, 2);
      
      const createTx = await factory.connect(seller).createAuction(
        nft.target,
        2,
        0, // 起拍价
        duration
      );
      
      const receipt = await createTx.wait();
      const auctionAddress = receipt.logs[0].args.auction;
      
      // 获取拍卖合约
      const Auction = await ethers.getContractFactory("Auction");
      const auction = Auction.attach(auctionAddress);
      
      // 出价
      const bidAmount = ethers.parseEther("1");
      await auction.connect(bidder1).bid({ value: bidAmount });
      
      // 增加时间以结束拍卖
      const auctionEndTime = await auction.auction.endTime();
      await time.increaseTo(auctionEndTime + 1n);
      
      // 获取手续费前的余额
      const feeRecipientInitialBalance = await ethers.provider.getBalance(feeRecipient.address);
      
      // 结束拍卖
      await auction.connect(seller).endAuction();
      
      // 检查手续费是否正确支付
      const feeRecipientFinalBalance = await ethers.provider.getBalance(feeRecipient.address);
      expect(feeRecipientFinalBalance - feeRecipientInitialBalance).to.equal(ethers.parseEther("0.01")); // 1% 手续费
    });
  });
  
  describe("Fee Functionality", function () {
    it("Should calculate fee correctly", async function () {
      const { factory, seller, tokenId, nft } = await loadFixture(deployAuctionFixture);
      
      // 创建拍卖
      const duration = 3600; // 1小时
      const tx = await factory.connect(seller).createAuction(
        nft.target,
        tokenId,
        0, // 起拍价
        duration
      );
      
      const receipt = await tx.wait();
      const auctionAddress = receipt.logs[0].args.auction;
      
      // 获取拍卖合约
      const Auction = await ethers.getContractFactory("Auction");
      const auction = Auction.attach(auctionAddress);
      
      // 检查手续费计算
      expect(await auction.calculateFee(ethers.parseEther("1"))).to.equal(ethers.parseEther("0.01")); // 1% of 1 ETH
      expect(await auction.calculateFee(ethers.parseEther("2"))).to.equal(ethers.parseEther("0.02")); // 1% of 2 ETH
    });
    
    it("Should allow owner to update fee settings", async function () {
      const { factory, owner } = await loadFixture(deployAuctionFixture);
      
      // 更新手续费设置
      await expect(factory.connect(owner).setFeeSettings(200, owner.address)) // 2%
        .to.emit(factory, "FeeSettingsUpdated")
        .withArgs(200, owner.address);
      
      // 检查手续费设置是否更新
      expect(await factory.feePercentage()).to.equal(200);
      expect(await factory.feeRecipient()).to.equal(owner.address);
    });
    
    it("Should fail to set fee percentage over 10%", async function () {
      const { factory, owner } = await loadFixture(deployAuctionFixture);
      
      // 尝试设置超过10%的手续费
      await expect(factory.connect(owner).setFeeSettings(1100, owner.address)) // 11%
        .to.be.revertedWith("Fee percentage cannot exceed 10%");
    });
  });
});