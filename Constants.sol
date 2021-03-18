// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * simple Library holding up the Constants used across the Auction process
 * 
 * @author : Manik Jain
 */
library Constants {
    
    //a bidding must be active for atleast 10 minutes to let all players place their bid 
    uint constant BID_ACTIVE_TIME = 600;
    
    //the ideal time taken in seconds to mine a block on Ethereum mainnet
    uint constant BLOCK_MINE_TIME = 15;
    
    string constant INVALID_START_BLOCK = 'Invalid value passed in for startBlock';
    string constant INVALID_END_BLOCK = 'Invalid value passed in for endBlock';
    string constant BID_ACTIVE_DURATION = 'Bid must be active for atleast 10 minutes';
    string constant BID_INCREMENT_VALUE = 'Bid increment value should be atleast 5';
    
    //Valid Auction status
    enum BID{
        START, 
        CANCEL, 
        END
    }
    
    //events thrown from Auction functions
    event NEW_BID(string message, address bidder, uint value);
    event AMOUNT_WITHDRAWN(string message, address by);
    event AUCTION_CANCELLED(string message);
}