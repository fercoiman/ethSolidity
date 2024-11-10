// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Auction
 * @dev Gestión de una subasta con control de ofertas, reembolsos y extensión del tiempo.
 */
contract AuctionExample {
    address public owner;             // Dirección del creador del contrato.
    uint256 public auctionEndTime;    // Momento en que termina la subasta.
    uint256 public highestBid;        // Valor de la oferta más alta.
    address public highestBidder;     // Dirección del ofertante más alto.
    bool public ended;                // Estado de la subasta (finalizada o no).

    mapping(address => uint256) public deposits;  // Depósitos de los participantes.
    address[] public bidders;  // Lista de todos los ofertantes.

    event NewBid(address indexed bidder, uint256 amount);  // Evento para nueva oferta.
    event AuctionEnded(address winner, uint256 amount);    // Evento cuando termina la subasta.

    /**
     * @dev Modificador que asegura que solo el dueño pueda ejecutar ciertas funciones.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Owner Only Function");
        _;
    }

    /**
     * @dev Modificador que asegura que la subasta esté activa.
     */
    modifier onlyWhileActive() {
        require(block.timestamp < auctionEndTime, "Bid already Closed");
        require(!ended, "Bid Closed!");
        _;
    }

    /**
     * @dev Constructor que inicializa la subasta.
     * @param _duration Duración de la subasta en segundos.
     */
    constructor(uint256 _duration) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + _duration;
    }

    /**
     * @dev Función para ofertar. La oferta debe ser 5% mayor que la actual.
     */
    function bid() external payable onlyWhileActive {
        require(msg.value > 0, "La oferta debe ser mayor a cero.");
        uint256 minBid = highestBid + (highestBid * 5) / 100;  // Oferta mínima válida (5% superior).
        require(msg.value >= minBid, "Offer must be 5% greater than max Bid!");

        // Si no es la primera oferta del ofertante, acumulamos su depósito anterior.
        if (deposits[msg.sender] == 0) {
            bidders.push(msg.sender);
        }
        deposits[msg.sender] += msg.value;

        // Devolvemos la oferta anterior al ofertante más alto.
        if (highestBidder != address(0)) {
            payable(highestBidder).transfer(highestBid);
        }

        // Actualizamos la oferta más alta y su ofertante.
        highestBid = msg.value;
        highestBidder = msg.sender;

        // Extendemos la subasta si faltan menos de 10 minutos.
        if (auctionEndTime - block.timestamp < 10 minutes) {
            auctionEndTime += 10 minutes;
        }

        emit NewBid(msg.sender, msg.value);
    }

    /**
     * @dev Función para mostrar al ganador y la oferta ganadora.
     * @return ganador Dirección del ofertante ganador.
     * @return oferta Valor de la oferta ganadora.
     */
    function showWinner() external view returns (address ganador, uint256 oferta) {
        require(ended, "Bid is still open");
        return (highestBidder, highestBid);
    }

    /**
     * @dev Muestra la lista de ofertantes y sus montos.
     * @return Lista de ofertantes y montos ofertados.
     */
    function showBids() external view returns (address[] memory, uint256[] memory) {
        uint256[] memory amounts = new uint256[](bidders.length);
        for (uint256 i = 0; i < bidders.length; i++) {
            amounts[i] = deposits[bidders[i]];
        }
        return (bidders, amounts);
    }

    /**
     * @dev Finaliza la subasta y devuelve los depósitos a los perdedores.
     */
    function endAuction() external onlyOwner {
        require(block.timestamp >= auctionEndTime, "Bid not ended yet!");
        require(!ended, "La subasta ya ha sido finalizada.");

        ended = true;

        // Devolver depósitos a los ofertantes que no ganaron (menos 2%).
        for (uint256 i = 0; i < bidders.length; i++) {
            address bidder = bidders[i];
            if (bidder != highestBidder) {
                uint256 refund = deposits[bidder] - (deposits[bidder] * 2) / 100;
                deposits[bidder] = 0;
                payable(bidder).transfer(refund);
            }
        }

        emit AuctionEnded(highestBidder, highestBid);
    }

    /**
     * @dev Permite a los ofertantes retirar el exceso de sus depósitos.
     */
    function withdrawExcess() external {
        require(deposits[msg.sender] > highestBid, "There in no enough balance to withdraw");
        uint256 excess = deposits[msg.sender] - highestBid;
        deposits[msg.sender] = highestBid;  // Ajustar el depósito al valor de la oferta más alta.
        payable(msg.sender).transfer(excess);
    }
}
