// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.5.16 <0.6.0  ;



  interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}