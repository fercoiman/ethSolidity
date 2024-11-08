// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/*Funciones básicas

Ofertar: Permitir que los participantes hagan una oferta válida (superior en al menos 5% a la actual) mientras la subasta esté activa.
Mostrar ganador: Mostrar el ganador y el monto de la oferta ganadora.
Mostrar ofertas: Listar todos los ofertantes y sus montos.
Devolver depósitos: Al finalizar, devolver los depósitos a quienes no ganaron (menos una comisión del 2% para el gas).

Funcionalidades avanzadas
Reembolso parcial: Los participantes pueden retirar el exceso de su última oferta.
Extensión del plazo: La subasta se extiende 10 minutos con cada nueva oferta válida en los últimos 10 minutos.

Consideraciones importantes
Usen modificadores donde sea adecuado.
Asegúrense de manejar adecuadamente los errores y usar eventos para comunicar cambios de estado.
Documentación clara y completa explicando funciones, variables y eventos.

*/


contract Subasta {
    address payable public bidOwner;
    uint256 public bidStartTime;
    uint256 public bidEndTime;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public constant EXT_TIME = 10 minutes;
    uint256 public constant BID_INC_PERCENT = 5; // Aumento mínimo del 5%
    uint256 public constant COMMISSION_PERCENT = 2; // Comisión del 2% para el gas

    struct Oferta {
        address payable bidder;
        uint256 amount;
    }

    Oferta[] public ofertas;
    mapping(address => uint256) public remainingBalance;

    // Eventos
    event NuevaOferta(address indexed bidder, uint256 monto, uint256 timestamp);
    event GanadorAnunciado(address ganador, uint256 montoGanador);
    event DepositoDevuelto(address indexed oferente, uint256 monto);
    event ExtiendeSubasta(uint256 nuevaHoraFin);

    // Modificadores
    modifier onlyOwner() {
        require(msg.sender == bidOwner, "This feature is reserved to Owner");
        _;
    }

    modifier soloMientrasActiva() {
        require(block.timestamp <= bidEndTime, "Bid has ended");
        _;
    }

    // Constructor: Inicializar la subasta con los parámetros necesarios.
    constructor(uint256 _duration) {
        bidOwner = payable(msg.sender);
        bidStartTime = block.timestamp;
        bidEndTime = bidStartTime + _duration;
        highestBid = 0;
    }

    function ofertar() external payable soloMientrasActiva {
        require(msg.value > 0, "Bid must be greater than zero");

        uint256 nuevaOferta = remainingBalance[msg.sender] + msg.value;
        require(nuevaOferta >= highestBid + (highestBid * BID_INC_PERCENT) / 100, "Offer must be at least 5% higher");

        // Registrar la oferta
        ofertas.push(Oferta(payable(msg.sender), nuevaOferta));

        // Reembolso de cualquier exceso anterior del oferente
        if (remainingBalance[msg.sender] > 0) {
            uint256 exceso = remainingBalance[msg.sender];
            remainingBalance[msg.sender] = 0;
            payable(msg.sender).transfer(exceso);
        }

        // Actualizar la mejor oferta
        highestBidder = msg.sender;
        highestBid = nuevaOferta;
        remainingBalance[msg.sender] = nuevaOferta;

        emit NuevaOferta(msg.sender, nuevaOferta, block.timestamp);

        // Extender el tiempo si la oferta fue en los últimos 10 minutos
        if (block.timestamp >= bidEndTime - 10 minutes) {
            bidEndTime += EXT_TIME;
            emit ExtiendeSubasta(bidEndTime);
        }
    }

    function mostrarGanador() external view returns (address, uint256) {
        require(block.timestamp > bidEndTime, "La subasta aun esta en curso");
        return (highestBidder, highestBid);
    }

    function mostrarOfertas() external view returns (Oferta[] memory) {
        return ofertas;
    }

    function devolverDepositos() external payable onlyOwner {
        require(block.timestamp > bidEndTime, "La subasta aun esta en curso");
        for (uint256 i = 0; i < ofertas.length; i++) {
            address oferente = ofertas[i].bidder;
            uint256 montoOfrecido = remainingBalance[oferente];
            
            if (oferente != highestBidder && montoOfrecido > 0) {
                uint256 comision = (montoOfrecido * COMMISSION_PERCENT) / 100;
                uint256 montoDevuelto = montoOfrecido - comision;

                remainingBalance[oferente] = 0;
                payable(oferente).transfer(montoDevuelto);

                emit DepositoDevuelto(oferente, montoDevuelto);
            }
        }
        emit GanadorAnunciado(highestBidder, highestBid);
    }

    function retirarExceso() external {
        uint256 exceso = remainingBalance[msg.sender] - highestBid;
        require(exceso > 0, "No tiene suficiente exceso");
        
        remainingBalance[msg.sender] -= exceso;
        payable(msg.sender).transfer(exceso);
    }
}
