// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
especificaciones:
    Funciones:
       
        Mostrar ganador: Muestra el ofertante ganador y el valor de la oferta ganadora.
        Mostrar ofertas: Muestra la lista de ofertantes y los montos ofrecidos.
        Devolver depósitos: Al finalizar la subasta se devuelve el depósito a los ofertantes que no ganaron, descontando una comisión del 2% para el gas.
    Manejo de depósitos:
        Las ofertas se depositan en el contrato y se almacenan con las direcciones de los ofertantes.
    Eventos:
        Nueva Oferta: Se emite cuando se realiza una nueva oferta.
        Subasta Finalizada: Se emite cuando finaliza la subasta.

Funcionalidades avanzadas:

    Reembolso parcial:
        Los participantes pueden retirar de su depósito el importe por encima de su última oferta durante el desarrollo de la subasta.

Consideraciones adicionales:

    Se debe utilizar modificadores cuando sea conveniente.
    Para superar a la mejor oferta la nueva oferta debe ser superior al menos en 5%.
    El plazo de la subasta se extiende en 10 minutos con cada nueva oferta válida. Esta regla aplica siempre a partir de 10 minutos antes del plazo original de la subasta. De esta manera los competidores tienen suficiente tiempo para presentar una nueva oferta si así lo desean.
    El contrato debe ser seguro y robusto, manejando adecuadamente los errores y las posibles situaciones excepcionales.
    Se deben utilizar eventos para comunicar los cambios de estado de la subasta a los participantes.
    La documentación del contrato debe ser clara y completa, explicando las funciones, variables y eventos.
*/
contract Subasta {
    address payable public auctioneer;
    uint256 public bidStartTime; 
    uint256 public bidEndTime;
    uint256 public constant GAS_FEE_PERCENT = 2; // Comisión del 2%
    uint256 public constant EXTENSION_TIME = 10 minutes;
    uint256 public constant BID_INC_PERCENT = 5; // Aumento mínimo del 5%
    //uint256 public bidAmount;
    bool public auctionEnded;

    struct Bid {
        address payable bidder;
        uint256 amount;
    }

    Bid public highestBid;
    //estructura con las ofertas depositadas
    mapping(address => uint256) public deposits;
    
    Bid[] public bids;

    //Constructor. Inicializa la subasta con los parámetros necesario para su funcionamiento.
    constructor(uint256 _auctionDurationMinutes)
    {
        
        auctioneer = payable(msg.sender);
        bidStartTime = block.timestamp;
        bidEndTime = block.timestamp + (_auctionDurationMinutes * 1 minutes);
        auctionEnded = false;
    }

    // Eventos
    event NewBid(address indexed bidder, uint256 amount, uint256 timestamp);
    event AuctionExtended(uint256 newbidEndTime);
    event AuctionEnded(address winner, uint256 amount);
    /*    VEEEEERRRRRRR.  */

    event WeHaveAWinner(address ganador, uint256 montoGanador);
    event Refund(address indexed oferente, uint256 monto);


    modifier onlyAuctioneer() {
        require(
            msg.sender == auctioneer,
            "Only sender can perform this action."
        );
        _;
    }

    modifier onlyBeforeEnd() {
        require(block.timestamp < bidEndTime, "Auction has already ended.");
        _;
    }

    modifier onlyAfterEnd() {
        require(block.timestamp >= bidEndTime, "Auction is still in progress.");
        _;
    }

    //  Función ColocarOferta: Permite a los participantes ofertar por el artículo. 
    //  Para que una oferta sea válida debe ser mayor que la mayor oferta actual mas 5% 
    //  debe realizarse mientras la subasta esté activa.
    
    function placeBid(uint256 bidAmount) public payable onlyBeforeEnd {
        require(bidAmount > 0, "Bid amount must be greater than zero.");
        uint256 minBidAmount = highestBid.amount + (highestBid.amount * BID_INC_PERCENT) / 100;
        require(
            msg.value >= minBidAmount,
            "Bid must be at least 5% higher than the current highest bid."
        );

        // Almaceno oferta anterior para el posible reembolso
        if (highestBid.bidder != address(0)) {
            deposits[highestBid.bidder] += highestBid.amount;
        }

        highestBid = Bid(payable(msg.sender), msg.value);
        bids.push(highestBid);

        // Extiendo subasta si está dentro de los últimos 10 minutos del tiempo original
        if (block.timestamp >= bidEndTime - 10 minutes) {
            bidEndTime += 10 minutes;
            emit AuctionExtended(bidEndTime);
        }

        emit NewBid(msg.sender, msg.value,block.timestamp);
    }

    function getWinner() public view onlyAfterEnd returns (address, uint256) {
        require(auctionEnded, "Auction must be ended to get the winner.");
        return (highestBid.bidder, highestBid.amount);
    }

    function getBids() public view returns (Bid[] memory) {
        return bids;
    }

    function finalizeAuction() public onlyAuctioneer onlyAfterEnd {
        require(!auctionEnded, "Auction has already been finalized.");
        auctionEnded = true;

        uint256 gasFee = (highestBid.amount * GAS_FEE_PERCENT) / 100;
        auctioneer.transfer(highestBid.amount - gasFee);

        emit AuctionEnded(highestBid.bidder, highestBid.amount);
    }

    function withdrawPartialDeposit() public onlyBeforeEnd {
        uint256 refundableAmount = deposits[msg.sender];
        require(refundableAmount > 0, "No funds available for refund.");

        deposits[msg.sender] = 0;
        payable(msg.sender).transfer(refundableAmount);
    }

    function refundLosingBids() public onlyAfterEnd {
        require(auctionEnded, "Auction has not ended yet.");
        uint256 refundAmount = deposits[msg.sender];
        require(refundAmount > 0, "No refund available.");

        uint256 gasFee = (refundAmount * GAS_FEE_PERCENT) / 100;
        uint256 refundWithFee = refundAmount - gasFee;

        deposits[msg.sender] = 0;
        payable(msg.sender).transfer(refundWithFee);
    }
}
