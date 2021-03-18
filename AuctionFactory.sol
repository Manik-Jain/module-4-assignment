// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Auction.sol';
import './Blocks.sol';

/**
 * @dev     : contract factory that helps to deploy Auction contract on demand
 * @author  : Manik Jain
 */
contract AuctionFactory {
    
    //maintains an array of all the auction contracts being deployed
    address[] auctions;
    
    //event emitted upon Auction contract being deployed
    event AuctionCreated(address auctionContract, address owner, uint _startBlock, uint _endBlock);
    
    //returns addresses of all the contracts being deployed
    function allAuctions() public view returns (address[] memory) {
        return auctions;
    }
    
    /**
     * create and deploy a new Auction contract depending upon the input parameters
     * 
     * Assumption : Auction should be valid for atleast 10 minutes
     * 
     * Params - 
     * 1. bidIncrement  : the incremental steps in which consecutive bids should differ
     * 2. _startBlock   : the assigned block when to deploy the Auction contract
     * 3. _endBlock     : the chain block number uptil when the Auction should be active
     * 
     * Emits AuctionCreated event with _startBlock and _endBlock.
     */
    function createAuction(uint bidIncrement, uint _startBlock, uint _endBlock) public {
        Blocks blocks = new Blocks();
        uint currentBlock = blocks.getCurrentBlock();
        _startBlock = _startBlock > currentBlock ? _startBlock : currentBlock + 1;
        _endBlock = _endBlock > currentBlock + 41 ? _endBlock : currentBlock + 41;
        Auction newAuction = new Auction(bidIncrement, _startBlock, _endBlock);
        auctions.push(address(newAuction));
        emit AuctionCreated(address(newAuction), msg.sender, _startBlock, _endBlock);
    }
}