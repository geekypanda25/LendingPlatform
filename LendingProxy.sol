// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import {IERC20} from './IERC20.sol';
import {LendingValidator} from './LendingValidator.sol';
import {Lender} from './Lender.sol';


contract LendingProxy {

    struct Loan{
        address borrowcur;
        uint256 principal;
        uint256 interest;
        uint256 apr;
        address collateral;
        uint256 collateralamt;
        address lendee;
        uint256 escrowed;
        uint256 timeperiod; 
        bool health;
        bool funded;
        bool closed;
    }

    mapping(uint256 => Loan) loans;

    address validator;

    mapping(address => address) currency;

    mapping(address => uint256[]) loanIDs;

    address lender;

    uint256 currloan;

    function check(address pmttoken, address requester, address borrtok, uint256 lendamt) public view returns(bool){
       
       bool pass = LendingValidator(validator).verify(requester, pmttoken, borrtok, lendamt);
       
       if(pass){
        
        return true;

       }else{

        return false;

       }

    }

    
    function calcapr(uint256 ln) public returns(uint256){

        require(!loans[ln].closed, "Already closed");

        uint256 ap; 

        (ap , loans[currloan].interest )= LendingValidator(validator).interest(loans[ln].lendee, loans[ln].collateral, loans[ln].borrowcur, loans[ln].principal, loans[ln].timeperiod);

        return ap;

    }

    function health(uint256 ln)public returns(bool){
        
        bool pass = LendingValidator(validator).verify(loans[ln].lendee, loans[ln].collateral, loans[ln].borrowcur, loans[ln].principal);

        if(pass){

            if(loans[ln].timeperiod < block.timestamp){

                return true;
            }
            else {

                liquidate(ln);

                return false;

            }

        } else {

            liquidate(ln);
            
            return false;

        }
    }

    //will need to Gelato automate
    function refresh()public{
    
        for(uint256 i = 0; i<currloan;i++){
            if(!loans[i].closed){

                loans[i].health = health(i);

            } else {

                loans[i].health = false;

            }
        }
    }

    function escrow(uint256 lo)internal{
        require(!loans[lo].closed, "Already closed");

        Lender(lender).escrow(loans[lo].lendee, loans[lo].collateral, loans[lo].collateralamt);
    
    }

    function loan(address borcurr, uint256 amt, address payment, uint256 deadline)public{

        bool qual = check(payment, msg.sender, borcurr, amt);

        if(qual){

            loans[currloan].principal = amt;

            loans[currloan].borrowcur = borcurr;

            loans[currloan].timeperiod = deadline;

            loans[currloan].collateral = payment;

            loans[currloan].lendee = address(msg.sender);

            loans[currloan].apr = calcapr(currloan);
            
            loans[currloan].collateralamt = LendingValidator(validator).getcollateral(borcurr, amt, payment);
    
            escrow(currloan);

            loans[currloan].funded = Lender(lender).fund(borcurr, msg.sender, amt);

            loans[currloan].health = qual;

        }

    }

    function collateralrequired(address borcurr, uint256 amt, address payment)external view returns(uint256){
        return LendingValidator(validator).getcollateral(borcurr, amt, payment);
    }
    
    function liquidate(uint256 ln)internal{

        require(!loans[ln].closed, "Already closed");

        loans[ln].escrowed = 0;

        Lender(lender).liquidate(loans[ln].lendee, loans[ln].collateral, loans[ln].collateralamt);

        loans[ln].closed = true;
    }

    function findloan(address user, address borr, address coll)external view returns(uint256){
        for(uint256 i = 0; i< loanIDs[user].length; i++){
            
            if(loan(loanIDs[user][i]).borcurr == bor){

                if(loan(loanIDs[user][i]).collateral == coll){
                
                    return loanIDs[user][i];
                
                }
            }
        }
    }

    function repay(address borcurr, address collat, uint256 amt) external {

        uint256 ln = findloan(msg.sender, borcurr, collat);

        require(IERC20(borcurr).balanceOf(msg.sender)>loans[ln].lendamt);

        Lender(lender).closeln();

    }

}