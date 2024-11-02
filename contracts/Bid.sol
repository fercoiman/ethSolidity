// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract Bid{


        uint256 finishTimestamp;        
        uint256 minimumInit;
        uint256 maxBid;
        address maxBidder;
        string startDate;
        uint256 bidDuration;
        uint32 minBidHops;
        uint32 newBidExtensionTime;

    constructor(uint256 _durationInSeconds) {
        finishTimestamp = block.timestamp + _durationInSeconds;

    }

    function makeBid() external payable {

        require(block.timestamp < finishTimestamp, "The Bid has Finished!");

        if(msg.value>maxBid){
            maxBid=msg.value;
            maxBidder = msg.sender;
        }
        else{
            revert("The bid is not enough");
        }

    }

}



