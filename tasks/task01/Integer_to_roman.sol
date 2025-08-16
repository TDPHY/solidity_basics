// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract IntegerToRoman {
//     12. 整数转罗马数字
// 七个不同的符号代表罗马数字，其值如下：

// 符号	值
// I	1
// V	5
// X	10
// L	50
// C	100
// D	500
// M	1000
// 罗马数字是通过添加从最高到最低的小数位值的转换而形成的。将小数位值转换为罗马数字有以下规则：

// 如果该值不是以 4 或 9 开头，请选择可以从输入中减去的最大值的符号，将该符号附加到结果，减去其值，然后将其余部分转换为罗马数字。
// 如果该值以 4 或 9 开头，使用 减法形式，表示从以下符号中减去一个符号，例如 4 是 5 (V) 减 1 (I): IV ，9 是 10 (X) 减 1 (I)：IX。仅使用以下减法形式：4 (IV)，9 (IX)，40 (XL)，90 (XC)，400 (CD) 和 900 (CM)。
// 只有 10 的次方（I, X, C, M）最多可以连续附加 3 次以代表 10 的倍数。你不能多次附加 5 (V)，50 (L) 或 500 (D)。如果需要将符号附加4次，请使用 减法形式。
// 给定一个整数，将其转换为罗马数字。

    // 定义数值与罗马符号的对应关系
    struct ValueSymbol {
        uint256 value;
        string symbol;
    }
    
    // 初始化数值-符号映射数组（从大到小排序）
    ValueSymbol[] private valueSymbols;

    constructor() {
        // 不直接赋值整个数组，而是通过 push 逐个添加元素
        valueSymbols.push(ValueSymbol(1000, "M"));
        valueSymbols.push(ValueSymbol(900, "CM"));
        valueSymbols.push(ValueSymbol(500, "D"));
        valueSymbols.push(ValueSymbol(400, "CD"));
        valueSymbols.push(ValueSymbol(100, "C"));
        valueSymbols.push(ValueSymbol(90, "XC"));
        valueSymbols.push(ValueSymbol(50, "L"));
        valueSymbols.push(ValueSymbol(40, "XL"));
        valueSymbols.push(ValueSymbol(10, "X"));
        valueSymbols.push(ValueSymbol(9, "IX"));
        valueSymbols.push(ValueSymbol(5, "V"));
        valueSymbols.push(ValueSymbol(4, "IV"));
        valueSymbols.push(ValueSymbol(1, "I"));
    }

    // 整数转罗马数字函数
    function intToRoman(uint256 num) public view returns (string memory) {
        bytes memory roman = new bytes(0);
        
        for (uint256 i = 0; i < valueSymbols.length; i++) {
            ValueSymbol memory vs = valueSymbols[i];
            
            // 循环减去当前数值并拼接符号
            while (num >= vs.value) {
                num -= vs.value;
                // 拼接符号到结果
                roman = abi.encodePacked(roman, vs.symbol);
            }
            
            // 数值减为0时提前退出循环
            if (num == 0) {
                break;
            }
        }
        
        // 将bytes转换为string返回
        return string(roman);
    }
}