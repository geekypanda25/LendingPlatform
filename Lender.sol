// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


import {IERC20} from './IERC20.sol';
import "./IPYESwapFactory.sol";
import "./IPYESwapRouter.sol";
import "./IPYESwapPair.sol";

contract Lender{

     modifier onlyProxy() {
        require(msg.sender == address(0x0), "Not proxy");
        _;
    }

    struct escrowed{

        address[] curr;

        mapping(address => uint256) escrowamt;
    }

    mapping(address=> escrowed) esc;

    mapping(address => uint256) funds;

    mapping(address => bool) currency; 

    address router = 0xA8B5D59E36E26769925B22B73Cb1E2c568e2F570;

    address wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    function fund(address curr, address cust, uint256 am)external onlyProxy() returns(bool){
       
        IERC20(curr).transferFrom(address(this), cust, am);
       
        funds[curr]-=am;

        esc[cust].escrowamt[curr] += am;

        esc[cust].curr.push(curr);

        return true;
    }

    function liquidate(address borrower, address curr, uint256 amt)external onlyProxy() {

        if(currency[curr]){

            esc[borrower].escrowamt[curr] -= amt;

            funds[curr] += amt;

        } else {

            address[] memory pair;

            pair[0] = curr;

            pair[1] = wbnb;

            esc[borrower].escrowamt[curr] -=amt;

            uint[] memory amounts = IPYESwapRouter(router).swapExactTokensForTokens(amt, 0, pair, address(this), block.timestamp);

            funds[wbnb] += amounts[amounts.length - 1];

        }
    }

    function escrow(address borrower, address coll, uint256 amt)external onlyProxy(){
        
        IERC20(coll).transferFrom(borrower, address(this), amt);
        
        esc[borrower].escrowamt[coll] += amt;
    
    }

    function closeln(address borrower, address coll, address borrowcur, uint256 amt, uint256 repayedamt ) external onlyProxy(){

        IERC20(coll).transferFrom(address(this), borrower, amt);

        esc[borrower].escrowamt[coll] -= amt;

        funds[borrowcur]+=repayedamt;
    }

}