// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

/*Funciones básicas
Constructor: Inicializar la subasta con los parámetros necesarios.
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
contract TPSubasta{
     // Variables de estado
    address public owner;
    uint256 public tiempoInicio;
    uint256 public duracionSubasta;
    address public ganador;
    uint256 public ofertaGanadora;
    bool public subastaActiva;

    struct Oferta {
        address ofertante;
        uint256 monto;
    }

    // Mapeos
    mapping(address => uint256) public depositos;
    mapping(uint256 => Oferta) public ofertas;
    uint256 public totalOfertas;

    // Eventos
    event OfertaAceptada(address ofertante, uint256 monto);
    event SubastaExtendida(uint256 nuevoTiempoFinal);
    event GanadorDefinido(address ganador, uint256 monto);

    // Modificadores
    modifier soloPropietario() {
        require(msg.sender == owner, "Solo el propietario puede ejecutar esta funcion");
        _;
    }

    modifier subastaEnCurso() {
        require(subastaActiva && block.timestamp <= tiempoInicio + duracionSubasta, "La subasta no esta activa");
        _;
    }

    modifier subastaTerminada() {
        require(!subastaActiva && block.timestamp > tiempoInicio + duracionSubasta, "La subasta aun esta en curso");
        _;
    }

    // Constructor
    constructor(uint256 _duracionSubasta) {
        owner = msg.sender;
        tiempoInicio = block.timestamp;
        duracionSubasta = _duracionSubasta;
        ofertaGanadora = 0;
        subastaActiva = true;
    }

    // Función para realizar una oferta
    function ofertar() public payable subastaEnCurso {
        require(msg.value > 0, "La oferta debe ser mayor a cero");

        uint256 nuevaOferta = depositos[msg.sender] + msg.value;
        require(nuevaOferta >= ofertaGanadora * 105 / 100, "La oferta debe ser al menos un 5% mayor a la actual");

        // Actualizar el depósito y registrar la oferta
        depositos[msg.sender] = nuevaOferta;
        ofertas[totalOfertas] = Oferta(msg.sender, nuevaOferta);
        totalOfertas++;

        // Actualizar la oferta ganadora
        if (nuevaOferta > ofertaGanadora) {
            ofertaGanadora = nuevaOferta;
            ganador = msg.sender;
            emit OfertaAceptada(msg.sender, nuevaOferta);
        }

        // Extender la subasta si se realiza una oferta en los últimos 10 minutos
        if (block.timestamp + 10 minutes >= tiempoInicio + duracionSubasta) {
            duracionSubasta += 10 minutes;
            emit SubastaExtendida(tiempoInicio + duracionSubasta);
        }
    }

    // Función para finalizar la subasta y devolver depósitos a los perdedores
    function finalizarSubasta() public soloPropietario subastaEnCurso {
        
        subastaActiva = false;
        emit GanadorDefinido(ganador, ofertaGanadora);
    }

    // Función para retirar depósitos no ganadores
    function retirarDeposito() public subastaTerminada {
        require(msg.sender != ganador, "El ganador no puede retirar el deposito");

        uint256 deposito = depositos[msg.sender];
        require(deposito > 0, "No tienes fondos para retirar");

        uint256 montoRetiro = deposito * 98 / 100; // Descontar comisión del 2%
        depositos[msg.sender] = 0;

        payable(msg.sender).transfer(montoRetiro);
    }

    // Función para realizar retiros parciales del exceso de la última oferta
    function retirarExceso() public subastaEnCurso {
        require(depositos[msg.sender] > ofertaGanadora, "No tienes exceso de oferta");

        uint256 exceso = depositos[msg.sender] - ofertaGanadora;
        depositos[msg.sender] -= exceso;

        payable(msg.sender).transfer(exceso);
    }

    // Función para obtener al ganador y la oferta ganadora
    function mostrarGanador() public view returns (address, uint256) {
        return (ganador, ofertaGanadora);
    }

    // Función para mostrar todas las ofertas
    function mostrarOfertas() public view returns (Oferta[] memory) {
        Oferta[] memory listaOfertas = new Oferta[](totalOfertas);
        for (uint256 i = 0; i < totalOfertas; i++) {
            listaOfertas[i] = ofertas[i];
        }
        return listaOfertas;
    }

}