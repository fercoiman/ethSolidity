// SPDX-License-Identifier: MIT
pragma solidity > 0.5.8;

contract Subasta{
    //variables de estado
    uint256 public valorInicial;
    uint256 public fechaInicio;
    uint256 public tiempoDuracion;
    uint256 public mayorOferta;
    address public oferenteGanador;
    uint8 public bidIsopen;
    address public owner;
    mapping (address => uint256) public valorMetido;

    constructor(){
        bidIsopen = 1;
        owner = msg.sender;
        valorInicial = 1 gwei;
        fechaInicio = block.timestamp;
        tiempoDuracion = fechaInicio + 7 days;
    }

    //mostrar ganador y mayor oferta

    function getOferenteGanador() external view returns(address){
        return oferenteGanador;
    }

    function getMayorOferta() external view returns (uint256){
        return mayorOferta;
    }

    // setter oferta
    function setOferta() external payable{
        
        //require(bidIsopen==1,"Subasta Finalizada");
        uint256 _valorOfertado = msg.value;
        require(_valorOfertado > valorInicial,"La oferta debe ser mayor que el valor incial");
        
        if(_valorOfertado > mayorOferta){
            address _addrOferente = msg.sender;
            mayorOferta = _valorOfertado;
            oferenteGanador = _addrOferente;   
        }
    }

    function finalizarSubasta() external {
        require(owner==msg.sender, "Usted no tiene permisos");
        bidIsopen = 0;
    }


}
