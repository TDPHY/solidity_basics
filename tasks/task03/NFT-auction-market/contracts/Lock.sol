// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/**
 * @title Lock 时间锁合约
 * @dev 一个简单的时间锁合约，允许在特定时间后提取资金
 *      主要用于演示基本的Solidity功能
 */
contract Lock {
  uint public unlockTime;      // 解锁时间
  address payable public owner; // 合约所有者

  event Withdrawal(uint amount, uint when); // 提取事件

  /**
   * @dev 构造函数，初始化时间锁合约
   * @param _unlockTime 解锁时间（Unix时间戳）
   */
  constructor(uint _unlockTime) payable {
    require(
      block.timestamp < _unlockTime,
      "Unlock time should be in the future"
    );

    unlockTime = _unlockTime;
    owner = payable(msg.sender);
  }

  /**
   * @dev 提取资金函数，只有在解锁时间之后且调用者为所有者时才能提取
   */
  function withdraw() public {
    // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
    // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

    require(block.timestamp >= unlockTime, "You can't withdraw yet");
    require(msg.sender == owner, "You aren't the owner");

    emit Withdrawal(address(this).balance, block.timestamp);

    owner.transfer(address(this).balance);
  }
}