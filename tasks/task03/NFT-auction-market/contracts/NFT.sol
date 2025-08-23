// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFT 合约
 * @dev 实现了基本的NFT功能，继承自OpenZeppelin的ERC721和Ownable合约
 */
contract NFT is ERC721, Ownable {
    uint256 private _tokenIds;                          // NFT代币ID计数器
    mapping(uint256 => string) private _tokenURIs;      // NFT代币URI映射

    /**
     * @dev 构造函数，初始化NFT合约
     * 设置NFT名称为"AuctionNFT"，代号为"ANFT"
     */
    constructor() ERC721("AuctionNFT", "ANFT") Ownable(msg.sender) {}

    /**
     * @dev 铸造新的NFT
     * @param recipient NFT接收者地址
     * @param tokenURI_ NFT的元数据URI
     * @return newItemId 新铸造的NFT的ID
     */
    function mint(address recipient, string memory tokenURI_) 
        public 
        onlyOwner 
        returns (uint256) 
    {
        _tokenIds++;
        uint256 newItemId = _tokenIds;
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI_);

        return newItemId;
    }

    /**
     * @dev 内部函数，设置NFT的URI
     * @param tokenId NFT代币ID
     * @param tokenURI_ NFT的元数据URI
     */
    function _setTokenURI(uint256 tokenId, string memory tokenURI_) 
        internal 
        virtual 
    {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = tokenURI_;
    }

    /**
     * @dev 获取NFT的URI
     * @param tokenId NFT代币ID
     * @return NFT的元数据URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }
    
    /**
     * @dev 检查NFT是否存在
     * @param tokenId NFT代币ID
     * @return bool NFT是否存在
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}