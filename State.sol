// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';

/**
 * @dev     : Simple contract to hold the state variables, whcih are shared across Auction helper contracts.
 *            A number of getter/setter functions are provided for easy access to the state variables.
 * 
 * @author  : Manik Jain
 */
contract State is Ownable {
    
    //the timed start block for the contract deployment
    uint private startBlock;
    
    //the timed end block for the contract deployment
    uint private endBlock;    
    
    //the incremental steps between consecutive bids
    uint private bidIncrement;
    
    //the current status of Auction. Acceptable -> { start, cancel, End }
    uint private auctionStatus;
    
    //the highest bid placed by the bidder
    uint internal highestBindingBid;
    
    //address of the highest bidder
    address internal highestBidder;
    
    //holds a mapping of bidder to the amout
    mapping (address => uint) internal fundsByBidder;
    
    //signify if the owner has withdrawn the (excess) ethers
    bool internal ownerHasWithdrawn;
    
    function getStartBlock() public view returns(uint){
        return startBlock;
    }
    
    function setStartBlock(uint _startBlock) internal onlyOwner() {
        startBlock = _startBlock;
    }
    
    function getEndBlock() public view returns (uint) {
        return endBlock;
    }
    
    function setEndBlock(uint _endBlock) internal onlyOwner() {
        endBlock = _endBlock;
    }
    
    function setBidIncrement(uint _bidIncrement) internal onlyOwner() {
        bidIncrement = _bidIncrement;
    }
    
    function getBidIncrement() public view returns(uint) {
        return bidIncrement;
    }
    
    function setAuctionStatus(uint _auctionStatus) internal onlyOwner() {
        auctionStatus = _auctionStatus;
    }
    
    function getAuctionStatus() public view returns(uint) {
        return auctionStatus;
    }
}