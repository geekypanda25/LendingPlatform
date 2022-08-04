

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IPYESwapRouter {
    function factory() external pure returns (address);
    
    function getPair(address tokenA,address tokenB) external returns (address);

     function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) ;
}