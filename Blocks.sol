// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Helper Contract to get the current block number.
 * This simple contract can be invoked before deploying the 
 * Auction contract, so as to be aware of the current block number.
 * 
 * An idea of the current block number before deployment can help to 
 * plan the deployment of the Auction.
 * 
 * @author : Manik Jain
 */
contract Blocks {
    
    function getCurrentBlock() public view returns (uint){
        return block.number;
    }
}