// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract BinarySearch {
    // 在一个有序数组中查找目标值
    // 在升序数组中查找目标值，返回索引（不存在则返回 type(uint256).max 表示 -1）
    function search(uint256[] calldata nums, uint256 target) public pure returns (uint256) {
        uint256 left = 0; // 左指针，指向数组起始位置
        uint256 right = nums.length - 1; // 右指针，指向数组末尾位置

        // 当左指针 <= 右指针时，继续查找
        while (left <= right) {
            // 计算中间索引（避免溢出：等价于 (left + right) / 2，但更安全）
            uint256 mid = left + (right - left) / 2;

            if (nums[mid] == target) {
                return mid; // 找到目标值，返回索引
            } else if (nums[mid] < target) {
                // 中间值小于目标值，目标值在右半部分，移动左指针
                left = mid + 1;
            } else {
                // 中间值大于目标值，目标值在左半部分，移动右指针
                right = mid - 1;
            }
        }

        // 循环结束仍未找到，返回 type(uint256).max 表示 -1（Solidity 无负数索引）
        return type(uint256).max;
    }
}