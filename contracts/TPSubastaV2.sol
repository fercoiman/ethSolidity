// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TPSubastaV2 {
    address public auctioneer;
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
    Bid public bid;

    mapping(address => uint256) public deposits;
    Bid[] public bids;

    constructor(uint256 _auctionDurationMinutes) {
        auctioneer = msg.sender;
        bidStartTime = block.timestamp;
        bidEndTime = block.timestamp + (_auctionDurationMinutes * 1 minutes);
        auctionEnded = false;
    }
    //Eventos que vamos a loggear: Nueva oferta, Subasta Extendida,Fin de subasta,Devolucion
    event NewBid(address indexed bidder, uint256 amount, uint256 timestamp);
    event AuctionExtended(uint256 newBidEndTime);
    event AuctionEnded(address winner, uint256 amount);
    event Refund(address indexed bidder, uint256 amount);

    //Modifier Solo el que inicia subasta puede finalizarla
    modifier onlyAuctioneer() {
        require(msg.sender == auctioneer, "Only auctioneer can finalize.");
        _;
    }
    //Modifier solo si subasta esta activa 
    modifier onlyBeforeEnd() {
        require(block.timestamp < bidEndTime, "Auction has ended.");
        _;
    }
    //Modifier solo si subasta ha terminado 
    modifier onlyAfterEnd() {
        require(block.timestamp >= bidEndTime, "Auction still in progress.");
        _;
    }

    //Funcion Colocar Oferta
    function placeBid(uint256 bidAmount) public payable onlyBeforeEnd {
        require(bidAmount > 0, "Bid must be greater than zero.");
        uint256 minBidAmount = highestBid.amount + (highestBid.amount * BID_INC_PERCENT) / 100;
        require(msg.value >= minBidAmount, "Bid must be at least 5% higher.");
        address bidder = msg.sender;
        uint256 amount = msg.value;

        //Guardamos -si es que existe- el monto de la mayor oferta previa 
        if (highestBid.bidder != address(0)) {
                deposits[highestBid.bidder] += highestBid.amount;
            }
        //actualizamos la nueva mayor oferta y la agrego a la lista de bids
            highestBid = Bid(payable(bidder), amount);
            bids.push(highestBid);
        
        // Extiende la subasta cada vez que se recibe una oferta en los últimos 10 minutos
        if(block.timestamp > bidEndTime - 10 minutes){
            bidEndTime += EXTENSION_TIME;
            emit AuctionExtended(bidEndTime);
        }
        //Logging nueva oferta
            emit NewBid(msg.sender, msg.value, block.timestamp);
    }

    //Funcion retiro exceso superior a la mayor oferta -antes del fin de la subasta-
    function withdrawExcessDeposit() public onlyBeforeEnd {
        uint256 depositedAmount = deposits[msg.sender];
        uint256 excess = depositedAmount - highestBid.amount;
        
        require(excess > 0, "No excess deposit available!");
        deposits[msg.sender] -= excess; //Descontamos el exceso
        payable(msg.sender).transfer(excess); //pagamos el exceso
        emit Refund(msg.sender, excess); //logging de la devolución
    }


    //Mostrar ganador de la subasta
    function getWinner() public view onlyAfterEnd returns (address, uint256) {
        require(auctionEnded, "Auction not finalized yet.");
        return (highestBid.bidder, highestBid.amount);
    }
    //Funcion finalizar subasta
    function finalizeAuction() public onlyAuctioneer {
        require(!auctionEnded, "Auction already finalized.");
        auctionEnded = true;
        //calculamos gas consumido
        uint256 gasFee = (highestBid.amount * GAS_FEE_PERCENT) / 100; 
        //descontamos gas
        payable(auctioneer).transfer(highestBid.amount - gasFee);
        emit AuctionEnded(highestBid.bidder, highestBid.amount);
    }
    //devolucion manual de las ofertas perdedoras (menos gas fee)
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
