# module-4-assignment
CSBC 2010 Auction contract assignment

## You will be developing a decentralized auction application. This application is complex so it is imperative to plan before writing the contracts. This exercise will also set a stage to explore the number of architectural best practices that will be beneficial down the road.

### Interface
Let us start with writing an interface. The auctions contract will have a simple interface that will
- Allow users to place bids
- Withdraw funds after the auction is complete
- Enable the owner to cancel the auction in some cases
- Allow the user to withdraw the winning bid

In order to handle the above functionality, develop an interface called IAuction that has
- A function called `placeBid` and returns a `bool`
- A function called `withdraw` and returns a `bool`
- A function called `cancelAuction` and returns a `bool`

### Contract
Let us start developing the contract called Auction with the following state variables
- Give a variable called `owner` (an `address`)
- Give a variable called `startBlock` (a `uint`)
- Give a variable called `endBlock` (a `uint`)
- Give a variable called `bidIncrement` (a `uint`)
- Give a variable called `cancelled` (a `bool`)
- Give a variable called `highestBidder` (a `address`)
- Give a variable called `fundsByBidder` (a `mapping (address => uint256)`)
- Give a variable called `highestBindingBid` (a `uint`)
- Give a variable called `ownerHasWithdrawn` (a `uint`)

If the auction completes successfully , there must be a person to whom the winning bid will go - owner. 

- There is a specific start and end time for the auctions. 
- The best practise to handle time in Solidity is to use `block.number` instead of spoofable `block.timestamp`. 
- We know that it requires 15 seconds on average to mine a block on Ethereum and eventually we can leverage timestamps from this number - `startBlock` and `endBlock`. 

#### `bidIncrement` and `highestBindingBid`
- If the current bid is CAD 50 and the bidIncrement is CAD 5. 
- If you have decided to bid CAD 100 but you are just required to pay CAD 55. 
- If you win the auction in this case, CAD 55 is the `highesBindingBid`. - If someone comes in the bid CAD 60, you are still the `highestBidder` but `highestBindingBid` will be raised to CAD 65. 
- It seems like the auction contract will automatically bid for you but with a cap and you are required to raise your bid or leave. 
- The contract will refund you the excess of `highestBindingBid` if you win the auction. 

### Let us write the constructor

The constructor function will initialize the `owner`, `bidIncrement`, `startBlock` and `endBlock` state variables. We will refuse to create a contract with invalid times i.e. it is logical to have start time before end time, start time must be also after the current block (we cannot an auction which started in the past). The address value of the owner should be also valid. Use following signature

```js
constructor (address _owner, uint _bidIncrement, uint _startBlock, uint _endBlock) public {
	// Check for valid values
	// Write code to initialize the state variables
}
```

#### Developing placeBid function 

The bidder should not be allowed to place the bid before the auction starts, after the auction ends or if it's cancelled. Also the owner of the Auction contract should not be allowed to place the bid because of the owner having control of running up the price to earn more profits. Here is the starter snippet for the placeBid function.

```js
function placeBid() 
    onlyAfterStart 
    onlyBeforeEnd 
    onlyNotCancelled 
    onlyNotOwner 
returns (bool success) {
    // logic goes here
}
```

For example, if you need a modifier say `onlyActive` to prevent access to certain actions unless auction is not actually activated, then the modifier looks as shown below.

```js
    modifier onlyActivate {
	    require(cancelled,”Auction: The auction is not cancelled”);
	    require(block.number < startBlock || block.number > endBlock,”Auction: The auction is not started yet”);
        _;
    }
```

- We’ll define the body of each modifier used with the `placeBid` function. 
- `onlyAfterStart` modifier will revert the transaction if the `block.number` is less than `startBlock`.
- `onlyBeforeEnd` modifier will revert the transaction if block number is greater than `endBlock`.
- `onlyNotCancelled` modifier will revert the transaction if `cancel` is true.

- Now it is the time to plan the logic that will go inside the body of the `placeBid` function. 
- This function should be able to accept Ethers and based on its value the bidder will either become `highestBidder` or cause the `highestbindingBid` to rise. 
- The contract’s storage variable like `fundsByBidder` is also calculated in this function.
- If the bidder has outbid, the Ether remains locked up in the contract until auction ends after which the bidder can withdraw manually. 
- But if the same `bidder` who was outbid earlier and increases the Ether to become `highestBidder` then they will only need to send the amount of Ether which will bring up the total over the current highest bid.
- For example, if you bid 1 Ether and someone else bids 2 Ethers; to outbid them, you only need to send minimum 3 Ethers next time calling `placeBid` function.The `placeBid` function looks as shown below.

```js
    function placeBid()
    public
        payable
        onlyAfterStart
        onlyBeforeEnd
        onlyNotCanceled
        onlyNotOwner
        returns (bool success)
    {
        // only accept non zero payments
        if (msg.value == 0) {revert();}

        // add the bid sent to make total amount of the bidder            
        uint newBid = fundsByBidder[msg.sender] + msg.value;

        // user must send the bid amount greater than equal to 
        // highestBindingBid.
        if (newBid <= highestBindingBid) {revert();}

        // get the bid amount of highestBidder .
        uint highestBid = fundsByBidder[highestBidder];

        fundsByBidder[msg.sender] = newBid;

        if (newBid <= highestBid) {
            // Increase the highestBindingBid if the user has 
            // overbid the highestBindingBid but not highestBid. 
            // leave highestBidder alone

            highestBindingBid = min(newBid + bidIncrement, highestBid);
        } else {            
            // Make the new user highestBidder
            // if it has overbid highestBid completely

            if (msg.sender != highestBidder) {
                highestBidder = msg.sender;
                highestBindingBid = min(newBid, highestBid + bidIncrement);
            }
            highestBid = newBid;
        }

        emit LogBid(msg.sender, newBid, highestBidder, highestBid, highestBindingBid);
        return true;
    }
```

#### Developing withdraw function 

- The withdrawal should only be permitted after the auction is ended or cancelled. 
- This deduces that you will need another modifier to satisfy these conditions.


```js
    modifier onlyEndedOrCanceled {
             require(block.number < endBlock && !canceled);
             _;
    }
```

- As far as the implementation of withdraw function goes, only the `owner` is allowed to withdraw Ether equal to `highestBindingBid`. 
- The `highestBidder` should be allowed to withdraw remaining Ether sent over `highestBindingBid`. Also other bidders are allowed to withdraw Ether from their respected Ether.

```js
function withdraw() public
        onlyEndedOrCanceled
        returns (bool success)
    {
        address withdrawalAccount;
        uint withdrawalAmount;

        if (canceled) {
            // let everyone allow to withdraw if auction is cancelled
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];

        } else {
            // this logic will execute if auction finished
            // without getting cancelled
            if (msg.sender == owner) {
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
        if (!msg.sender.send(withdrawalAmount)) {revert();}

        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

        return true;
    }
```

### Developing cancelAuction function

This function will set the cancelled storage variable to true, log an event and return true.

```js
function cancelAuction() public
        onlyOwner
        onlyBeforeEnd
        onlyNotCanceled
        returns (bool success)
    {
        canceled = true;
        LogCanceled();
        return true;
    }
```

- You also need to create a factory contract for Auction using keyword new which will facilitate deploying of an auction contract. 

#### Develop a contract named `AuctionFactory.sol`.

- Give a public storage variable called auctions (an array of addresses) to store all the auctions.

    ```js
    address[] public auctions;
    ```

- Declare a public getter function that returns array of all the auctions created through 

    ```js
        function allAuctions() public view returns (address[] memory) {
            return auctions;
        }
    ```

- Create a public function called `createAuction` which accepts `bidIncrement`(an `uint`), `startBlock`(an `uint`) and `endBlock`(an `uint`) . The `bidIncrement` shows the step size of the bidding amount. `startBlock` and `endBlock` determines the start time and end time of the auction.
- Declare an event called  `AuctionCreated` that emits every time a new auction is created. It should emit all the details like address of the auction contract and creator of the auction contract.

```js
function createAuction(uint bidIncrement, uint startBlock, uint endBlock) public {
        Auction newAuction = new Auction(msg.sender, bidIncrement, startBlock, endBlock);
        auctions.push(address(newAuction));

        emit AuctionCreated(address(newAuction), msg.sender);
    }

    event AuctionCreated(address auctionContract, address owner);
```


Combining all the aspects covered so far, develop an Auction contract and submit your solution.
