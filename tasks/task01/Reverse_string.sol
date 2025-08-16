// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract ReverseString {
    //反转一个字符串。输入 "abcde"，输出 "edcba"
    function reverseString(string memory input) public pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        bytes memory reversedBytes = new bytes(inputBytes.length);
        for (uint256 i = 0; i < inputBytes.length; i++) {
            reversedBytes[i] = inputBytes[inputBytes.length - 1 - i];
        }
        return string(reversedBytes);
    }
}