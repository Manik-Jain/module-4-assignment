// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Constants.sol';
import './State.sol';

/**
 * @dev     : this contract provides the validation checks needed for Auction functions
 * @author  : Manik Jain
 * 
 */
contract Validations is State {
    
    //performs checks before the contract is deployed
    modifier beforeDeploy(uint _startBlock, uint _endBlock, uint _bidIncrement) {
        require(_startBlock > 0 && _startBlock > block.number, Constants.INVALID_START_BLOCK);
        require(_endBlock > _startBlock && _endBlock > block.number, Constants.INVALID_END_BLOCK);
        require((_endBlock - _startBlock) * Constants.BLOCK_MINE_TIME >= Constants.BID_ACTIVE_TIME, Constants.BID_ACTIVE_DURATION);
        require(_bidIncrement >=5 , Constants.BID_INCREMENT_VALUE);
        _;
    }
    
    modifier onlyAfterStart() {
        require(getAuctionStatus() == 0 || block.number < getStartBlock() || block.number > getEndBlock(), 'Bidding has not yet started.');
        _;
    }
    
    modifier onlyNotCancelled() {
        require(getAuctionStatus() != 1, 'Bidding has already been cancelled.');
        _;
    }
    
    modifier onlyBeforeEnd() {
        require(getAuctionStatus() != 2 || block.number > getEndBlock(), 'Bidding has already end.');
        _;
    }
    
    modifier onlyNotOwner() {
        require(msg.sender != owner(), 'Ownner cannot invoke the functionality.');
        _;
    }
    
    modifier minBid() {
        require(msg.value > 0, 'Only Non-Zero bid values are accepted.');
        require(msg.value >= getBidIncrement(), 'Bids must be atleast in succession of increments defined');
        _;
    }
    
    modifier onlyEndedOrCanceled() {
        require(getAuctionStatus() == 1 || getAuctionStatus() == 2, 'Cannot Withdraw on an on-going bid');
        _;
    }
}