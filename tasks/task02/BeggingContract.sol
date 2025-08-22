// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

//合约地址
// 0x2d3e5e237b7a2134b86f935889ba12c0464679a733dda56a97a0300e30928dfd


// ✅ 作业3：编写一个讨饭合约
// 任务目标
//     使用 Solidity 编写一个合约，允许用户向合约地址发送以太币。
//     记录每个捐赠者的地址和捐赠金额。
//     允许合约所有者提取所有捐赠的资金。

// 任务步骤
//     编写合约
//         创建一个名为 BeggingContract 的合约。
//         合约应包含以下功能：
//         一个 mapping 来记录每个捐赠者的捐赠金额。
//         一个 donate 函数，允许用户向合约发送以太币，并记录捐赠信息。
//         一个 withdraw 函数，允许合约所有者提取所有资金。
//         一个 getDonation 函数，允许查询某个地址的捐赠金额。
//         使用 payable 修饰符和 address.transfer 实现支付和提款。
//     部署合约
//         在 Remix IDE 中编译合约。
//         部署合约到 Goerli 或 Sepolia 测试网。
//     测试合约
//         使用 MetaMask 向合约发送以太币，测试 donate 功能。
//         调用 withdraw 函数，测试合约所有者是否可以提取资金。
//         调用 getDonation 函数，查询某个地址的捐赠金额。

// 任务要求
//     合约代码：
//         使用 mapping 记录捐赠者的地址和金额。
//         使用 payable 修饰符实现 donate 和 withdraw 函数。
//         使用 onlyOwner 修饰符限制 withdraw 函数只能由合约所有者调用。
//     测试网部署：
//         合约必须部署到 Goerli 或 Sepolia 测试网。
//     功能测试：
//         确保 donate、withdraw 和 getDonation 函数正常工作。

// 提交内容
//     合约代码：提交 Solidity 合约文件（如 BeggingContract.sol）。
//     合约地址：提交部署到测试网的合约地址。
//     测试截图：提交在 Remix 或 Etherscan 上测试合约的截图。

// 额外挑战（可选）
//     捐赠事件：添加 Donation 事件，记录每次捐赠的地址和金额。
//     捐赠排行榜：实现一个功能，显示捐赠金额最多的前 3 个地址。
//     时间限制：添加一个时间限制，只有在特定时间段内才能捐赠。

// 创建一个名为 BeggingContract 的合约。
contract BeggingContract {
    // 记录合约所有者
    address public owner;

    // 一个 mapping 来记录每个捐赠者的捐赠金额。
    mapping (address => uint256) public donations;

    // 捐赠开始和结束时间
    uint256 public donationStartTime;
    uint256 public donationEndTime;
    
    // 捐赠排行榜前三名
    address[3] public topDonors;
    uint256[3] public topDonations;

    event Donation(address indexed donor, uint256 amount);

    // 构造函数，设置合约部署者为所有者和捐赠时间范围
    constructor(uint256 _startTime, uint256 _endTime) {
        require(_startTime < _endTime, "Start time must be before end time");
        owner = msg.sender;
        donationStartTime = _startTime;
        donationEndTime = _endTime;
    }

    // 仅所有者可执行的修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // 检查是否在捐赠时间范围内
    modifier duringDonationPeriod() {
        require(block.timestamp >= donationStartTime && block.timestamp <= donationEndTime, 
                "Donations are only allowed during the specified period");
        _;
    }

    // 一个 donate 函数，允许用户向合约发送以太币，并记录捐赠信息。
    function donate() public payable {
        // 确保捐赠金额大于0
        require(msg.value > 0, "Donation amount must be greater than 0");
         // 记录捐赠金额，累加之前的捐赠
        uint256 newTotal = donations[msg.sender] + msg.value;
        donations[msg.sender] = newTotal;
        // 更新排行榜
        updateTopDonors(msg.sender, newTotal);
        // 触发捐赠事件
        emit Donation(msg.sender, msg.value);
    }

    // 一个 withdraw 函数，允许合约所有者提取所有资金。
    function withdraw() public onlyOwner {
        // 获取合约当前余额
        uint256 balance = address(this).balance;
        // 确保合约有余额可提取
        require(balance > 0, "No funds to withdraw");
        // 将所有余额转移给所有者
        payable(owner).transfer(balance);
    }

    // 一个 getDonation 函数，允许查询某个地址的捐赠金额。
    function getDonation(address donor) public view returns (uint256) {
        return donations[donor];
    }
    
    // 更新捐赠排行榜
    function updateTopDonors(address donor, uint256 totalDonation) private {
        // 检查是否能进入前三名
        for (uint i = 0; i < 3; i++) {
            if (totalDonation > topDonations[i]) {
                // 从后往前移动排名
                for (uint j = 2; j > i; j--) {
                    topDonors[j] = topDonors[j-1];
                    topDonations[j] = topDonations[j-1];
                }
                // 插入新的排名
                topDonors[i] = donor;
                topDonations[i] = totalDonation;
                break;
            }
        }
    }

    // 获取当前捐赠排行榜
    function getTopDonors() public view returns (address[3] memory, uint256[3] memory) {
        return (topDonors, topDonations);
    }
    
    // 允许所有者调整捐赠时间
    function adjustDonationPeriod(uint256 _newStartTime, uint256 _newEndTime) public onlyOwner {
        require(_newStartTime < _newEndTime, "Start time must be before end time");
        donationStartTime = _newStartTime;
        donationEndTime = _newEndTime;
    }
    
}