// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import './PriceConsumerV3.sol';
import './IERC20.sol';

contract LendingValidator{

    struct curr{
        address aggr;
        bool supported;
    }
    
    mapping(address => curr) currency;

    uint256 apr;

    function addcurrency(address curren, address agg)public {

        currency[curren].aggr = agg;

        currency[curren].supported = true;
    }

    function updateapr(uint256 per) external {

        apr = per;
    
    }

    function verify(address borrower, address colladdr, address lendtok, uint256 amount)external view returns(bool){

        require(currency[colladdr].supported, "Unsupported collateral");

        require(currency[lendtok].supported, "Unsupported");

        uint256 borrowprice = uint256(PriceConsumerV3(currency[lendtok].aggr).getLatestPrice());

        uint256 collprice = uint256(PriceConsumerV3(currency[colladdr].aggr).getLatestPrice());

        bool pass;

        uint256 bal = IERC20(colladdr).balanceOf(borrower);

        if((bal * borrowprice) > (amount * collprice)){

            pass = true;

        } else {

            pass = false;
   
        }

        return pass;
    }

    function getcollateral(address borcurr, uint256 amt, address payment)external view returns(uint256){

        require(currency[payment].supported, "Unsupported collateral");

        require(currency[borcurr].supported, "Unsupported collateral");

        uint256 borrowprice = uint256(PriceConsumerV3(currency[borcurr].aggr).getLatestPrice());

        uint256 collprice = uint256(PriceConsumerV3(currency[payment].aggr).getLatestPrice());

        uint256 collamt = (borrowprice * amt)/collprice ;

        return collamt;
    }

    function interest(address borrower, address colladdr, address lendtok, uint256 lendamt, uint256 time)external returns(uint256, uint256){

        uint256 inter;

        inter = (apr/365) * (lendamt);

        return (apr, inter);

    }

    function 

}