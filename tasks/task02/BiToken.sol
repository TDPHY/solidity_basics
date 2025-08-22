// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

//合约地址
//0x876f46735dc75452398f358efcfde4adb4125aae2888a9c81d239713d5416709

// ✅ 作业 1：ERC20 代币
// 任务：参考 openzeppelin-contracts/contracts/token/ERC20/IERC20.sol实现一个简单的 ERC20 代币合约。要求：
// 合约包含以下标准 ERC20 功能：
// balanceOf：查询账户余额。
// transfer：转账。
// approve 和 transferFrom：授权和代扣转账。
// 使用 event 记录转账和授权操作。
// 提供 mint 函数，允许合约所有者增发代币。 提示：
// 使用 mapping 存储账户余额和授权信息。
// 使用 event 定义 Transfer 和 Approval 事件。
// 部署到sepolia 测试网，导入到自己的钱包
contract BiToken {
    //存储此Token的发行者。用于一些权限控制
    address private owner;

    // 代币名称
    string public name;
    // 代币符号
    string public symbol;
    // 小数位数
    uint8 public decimals = 18;
    //存储 Token 的总发行量。定义为 public，可以被任何人查询
    uint256 public totalSupply;

    //存储每个地址对应的余额
    mapping(address => uint256) private balances;
    // 存储授权信息 (owner => spender => amount)
    mapping(address => mapping(address => uint256)) public allowance;

    // 转账事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 授权事件
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // 构造函数，初始化代币信息
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        // 初始化供应量并分配给合约部署者
        totalSupply = _initialSupply * (10**uint256(decimals));
        mint(msg.sender, totalSupply);
    }

    //用于铸造 Token 的函数，只有所有者可以调用
    function mint(address recipient, uint256 amount) public {
        //确保接收增发代币的地址不是零地址
        require(recipient != address(0), "Mint to the zero address");
        //只有所有者可以调用
        require(msg.sender == owner, "Only owner can mint tokens");

        balances[recipient] += amount;
        totalSupply += amount;

        emit Transfer(address(0), recipient, amount);
    }

    //用于查询对应地址的余额
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    //用于转账的函数
    function transfer(address recipient, uint256 amount) public {
        //入参检查
        require(recipient != address(0), "Mint to the zero address");
        require(amount <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
    }

    // 授权函数
    function approve(address spender, uint256 amount) public {
        require(spender != address(0), "Approve to the zero address");

        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
    }

    // 授权转账函数
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(balances[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");

        balances[from] -= amount;
        balances[to] += amount;
        allowance[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
    }
}
