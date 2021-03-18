// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IBid.sol';
import './Validations.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol';

/**
 * @author  : Manik Jain
 * @dev     : Implementation of a standard Auction smart contract. 
 * 
 * This smart contract extends the following parent contracts/interfaces : 
 * 1. Ownable       - OpenZeppelin implementation of token ownership
 * 2. IBid          - Custom interface that declares the Bidding functions
 * 3. Validations   - provides the validations for the smart contract functions
 * 
 * Features :
 * 1. Allows to delpoy the Auction smart contract with passed in values for start block, end block, and incremental steps of bidding
 * 2. Place a new bid on the auction
 * 3. Allows the bidders/owner to withdraw the held up ethers
 * 4. Allows the contract owner to cancel an Auction at anytime
 * 5. View the bid placed by a bidding partner
 * 6. holds the ethers being under bid, and once the bid ends, the final amount can be withdrawn
 */
contract Auction is Ownable, IBid, Validations {
    
    /**
     * Allows to delpoy the Auction smart contract and
     * initialises the state variables upon performing the validations as part of beforeDeploy()
     * After the contract is deployed, the bidding status moves to STARTED status.
     * 
     * @dev : See also => Validations.beforeDeploy()
     */
    constructor (uint _bidIncrement, uint _startBlock, uint _endBlock) beforeDeploy(_startBlock, _endBlock, block.number) {
        setStartBlock(_startBlock);
	    setEndBlock(_endBlock);
	    setBidIncrement(_bidIncrement);
	    setAuctionStatus(uint(Constants.BID.START));
    }
    
    /**
     * Place a new bid on the auction
     * The bidding is allowed once the following checks are passed:
     * 
     * 1. Auction has been started
     * 2. Auction is yet active - not Ended or cancelled
     * 3. Owner cannot participate in bidding
     * 4. Bids must be incremented in steps as requested by the owner
     * 
     * This method emits NEW_BID upon a successful bid has been placed
     */
    function bid() external payable override onlyAfterStart() onlyBeforeEnd() onlyNotCancelled() onlyNotOwner() minBid() returns(bool) {
        uint newBid = fundsByBidder[_msgSender()] + msg.value;
        if (newBid <= highestBindingBid) {
            revert();
            
        }
        uint highestBid = fundsByBidder[highestBidder];
        fundsByBidder[_msgSender()] = newBid;
        
        if (newBid <= highestBid) {
            // Increase the highestBindingBid if the user has 
            // overbid the highestBindingBid but not highestBid. 
            // leave highestBidder alone

            highestBindingBid = Math.min(newBid + getBidIncrement(), highestBid);
        } else {            
            // Make the new user highestBidder
            // if it has overbid highestBid completely

            if (msg.sender != highestBidder) {
                highestBidder = msg.sender;
                highestBindingBid = Math.min(newBid, highestBid + getBidIncrement());
            }
            highestBid = newBid;
        }
        
        emit Constants.NEW_BID('New Bid received', msg.sender, msg.value);
        return true;
    }
    
    /**
     * Allows the bidders/owner to withdraw the held up ethers
     * The held up bidding amount can be withdrawn under the two conditions:
     * 
     * 1. The bidding has been Ended
     * 2. bidding has been cancelled
     * 
     * This method emits AMOUNT_WITHDRAWN event upon success
     */
    function withdraw() external payable override onlyEndedOrCanceled() returns(bool) {
        address withdrawalAccount;
        uint withdrawalAmount;
        
        if (getAuctionStatus() == 1) {
            // let everyone allow to withdraw if auction is cancelled
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];

        } else {
            // this logic will execute if auction finished
            // without getting cancelled
            if (_msgSender() == owner()) {
                // allow auction’s owner to withdraw 
                // highestBindingbid
                withdrawalAccount = highestBidder;
                withdrawalAmount = highestBindingBid;
                ownerHasWithdrawn = true;

            } else if (msg.sender == highestBidder) {
                // the highest bidder should only be allowed to 
                // withdraw the excess bid which is difference 
                // between highest bid and the highestBindingBid
                withdrawalAccount = highestBidder;
                if (ownerHasWithdrawn) {
                    withdrawalAmount = fundsByBidder[highestBidder];
                } else {
                    withdrawalAmount = fundsByBidder[highestBidder] - highestBindingBid;
                }

            } else {
                // the bidders who do not win highestBid are allowed
                // to withdraw their full amount
                withdrawalAccount = msg.sender;
                withdrawalAmount = fundsByBidder[withdrawalAccount];
            }
        }

        if (withdrawalAmount == 0) {revert();}

        fundsByBidder[withdrawalAccount] -= withdrawalAmount;

        // transfer the withdrawal amount
        //if (!payable(msg.sender).send(withdrawalAmount)) {revert();}
        
        payable(msg.sender).transfer(withdrawalAmount);

        emit Constants.AMOUNT_WITHDRAWN('amount withdrawn', _msgSender());
        return true;
    }
    
    /**
     * Allows the contract owner to cancel an Auction at anytime
     * 
     * This method emits AUCTION_CANCELLED event upon success
     */
    function cancel() external override onlyOwner() onlyBeforeEnd() onlyNotCancelled() returns(bool) {
        setAuctionStatus(uint(Constants.BID.CANCEL));
        emit Constants.AUCTION_CANCELLED('Auction cancelled');
        return true;
    }
    
    /**
     * View the bid placed by a bidding partner. 
     * It takes as input the bidder address as the input 
     * and returns the funds being put at bid
     */
    function getBid(address _bidder) public view returns (uint) {
        require(_bidder != address(0), 'Invalid Address');
        return fundsByBidder[_bidder];
    }
    
    ///Fallback function to handle any excess ethers
    receive() external payable {
        
    }
}
