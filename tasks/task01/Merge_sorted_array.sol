// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract MergeSortedArray{
    // 将两个有序数组合并为一个有序数组。
    // 合并两个有序数组（升序），返回新的有序数组
    function merge(uint256[] calldata nums1, uint256[] calldata nums2) public pure returns (uint256[] memory) {
        // 获取两个数组的长度
        uint256 len1 = nums1.length;
        uint256 len2 = nums2.length;
        // 初始化结果数组，长度为两个数组长度之和
        uint256[] memory result = new uint256[](len1 + len2);
        
        // 定义三个指针，分别指向nums1、nums2和result的当前位置
        uint256 i = 0; // nums1的指针
        uint256 j = 0; // nums2的指针
        uint256 k = 0; // result的指针
        
        // 当两个数组都未遍历完时，比较当前元素并放入结果数组
        while (i < len1 && j < len2) {
            if (nums1[i] <= nums2[j]) {
                result[k] = nums1[i];
                i++; // 移动nums1的指针
            } else {
                result[k] = nums2[j];
                j++; // 移动nums2的指针
            }
            k++; // 移动结果数组的指针
        }
        
        // 处理nums1中剩余的元素（若有）
        while (i < len1) {
            result[k] = nums1[i];
            i++;
            k++;
        }
        
        // 处理nums2中剩余的元素（若有）
        while (j < len2) {
            result[k] = nums2[j];
            j++;
            k++;
        }
        
        return result;
    }
}