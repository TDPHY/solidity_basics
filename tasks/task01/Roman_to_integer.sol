// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract RomanToInteger {
//     罗马数字转整数
// 提示
// 罗马数字包含以下七种字符: I， V， X， L，C，D 和 M。

// 字符          数值
// I             1
// V             5
// X             10
// L             50
// C             100
// D             500
// M             1000
// 例如， 罗马数字 2 写做 II ，即为两个并列的 1 。12 写做 XII ，即为 X + II 。 27 写做  XXVII, 即为 XX + V + II 。

// 通常情况下，罗马数字中小的数字在大的数字的右边。但也存在特例，例如 4 不写做 IIII，而是 IV。数字 1 在数字 5 的左边，所表示的数等于大数 5 减小数 1 得到的数值 4 。同样地，数字 9 表示为 IX。这个特殊的规则只适用于以下六种情况：

// I 可以放在 V (5) 和 X (10) 的左边，来表示 4 和 9。
// X 可以放在 L (50) 和 C (100) 的左边，来表示 40 和 90。 
// C 可以放在 D (500) 和 M (1000) 的左边，来表示 400 和 900。
// 给定一个罗马数字，将其转换成整数。

    // 映射存储罗马字符到对应数值的映射
    mapping(bytes1 => int256) private romanValues;

    // 构造函数：初始化罗马字符对应的数值
    constructor() {
        romanValues["I"] = 1;
        romanValues["V"] = 5;
        romanValues["X"] = 10;
        romanValues["L"] = 50;
        romanValues["C"] = 100;
        romanValues["D"] = 500;
        romanValues["M"] = 1000;
    }

    // 罗马数字转整数
    function romanToInteger(string memory input) public view returns (int256) {
        bytes memory inputBytes = bytes(input);
        uint256 length = inputBytes.length;
        int256 result = 0;

        for (uint256 i = 0; i < length; i++) {
            // 获取当前字符的数值
            int256 currentValue = romanValues[inputBytes[i]];

            // 若当前字符不是最后一个，且当前值小于下一个值，则做减法
            if (i < length - 1 && currentValue < romanValues[inputBytes[i + 1]]) {
                result -= currentValue;
            } else {
                // 否则做加法（正常规则）
                result += currentValue;
            }
        }

        
        return result;
    }
}