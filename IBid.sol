// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev     : Interface that declares Auction operations
 * @author  : Manik Jain
 */
interface IBid {
    
    //place a bid on the on-going auction
    function bid() external payable returns(bool);
    
    //withdraw the ethers once the auction is cancelled/ended
    function withdraw() external payable returns(bool);
    
    //cancel an on-going auction
    function cancel() external returns(bool);
}