// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Subasta {
    address payable public auctioneer;
    uint256 public bidStartTime; 
    uint256 public bidEndTime;
    uint256 public constant GAS_FEE_PERCENT = 2;
    uint256 public constant EXTENSION_TIME = 10 minutes;
    uint256 public constant BID_INC_PERCENT = 5;
    bool public auctionEnded;

    struct Bid {
        address payable bidder;
        uint256 amount;
    }

    Bid public highestBid;
    mapping(address => uint256) public deposits;
    Bid[] public bids;

    constructor(uint256 _auctionDurationMinutes) {
        auctioneer = payable(msg.sender);
        bidStartTime = block.timestamp;
        bidEndTime = block.timestamp + (_auctionDurationMinutes * 1 minutes);
        auctionEnded = false;
    }

    event NewBid(address indexed bidder, uint256 amount, uint256 timestamp);
    event AuctionExtended(uint256 newBidEndTime);
    event AuctionEnded(address winner, uint256 amount);
    event Refund(address indexed bidder, uint256 amount);

    modifier onlyAuctioneer() {
        require(msg.sender == auctioneer, "Only auctioneer can finalize.");
        _;
    }

    modifier onlyBeforeEnd() {
        require(block.timestamp < bidEndTime, "Auction has ended.");
        _;
    }

    modifier onlyAfterEnd() {
        require(block.timestamp >= bidEndTime, "Auction still in progress.");
        _;
    }

    function placeBid(uint256 bidAmount) public payable onlyBeforeEnd {
        require(bidAmount > 0, "Bid must be greater than zero.");
        uint256 minBidAmount = highestBid.amount + (highestBid.amount * BID_INC_PERCENT) / 100;
        require(msg.value >= minBidAmount, "Bid must be at least 5% higher.");

        if (highestBid.bidder != address(0)) {
            deposits[highestBid.bidder] += highestBid.amount;
        }

        highestBid = Bid(payable(msg.sender), msg.value);
        bids.push(highestBid);

        // Extiende la subasta cada vez que se recibe una oferta en los últimos 10 minutos
        if (block.timestamp >= bidEndTime - EXTENSION_TIME) {
            bidEndTime += EXTENSION_TIME;
            emit AuctionExtended(bidEndTime);
        }

        emit NewBid(msg.sender, msg.value, block.timestamp);
    }

    function getWinner() public view onlyAfterEnd returns (address, uint256) {
        require(auctionEnded, "Auction not finalized yet.");
        return (highestBid.bidder, highestBid.amount);
    }

    function finalizeAuction() public onlyAuctioneer onlyAfterEnd {
        require(!auctionEnded, "Auction already finalized.");
        auctionEnded = true;

        uint256 gasFee = (highestBid.amount * GAS_FEE_PERCENT) / 100;
        auctioneer.transfer(highestBid.amount - gasFee);

        emit AuctionEnded(highestBid.bidder, highestBid.amount);
    }

    function refundLosingBids() public onlyAfterEnd {
        require(auctionEnded, "Auction must be finalized first.");
        uint256 refundAmount = deposits[msg.sender];
        require(refundAmount > 0, "No refund available.");

        uint256 gasFee = (refundAmount * GAS_FEE_PERCENT) / 100;
        uint256 refundWithFee = refundAmount - gasFee;

        deposits[msg.sender] = 0;
        payable(msg.sender).transfer(refundWithFee);

        emit Refund(msg.sender, refundWithFee);
    }
}