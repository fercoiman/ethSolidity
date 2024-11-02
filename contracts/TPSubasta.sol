// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;

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
contract SubastaEthKipu{
    //Constructor: Inicializar la subasta con los parámetros necesarios.
    constructor() {
        console.log("Owner contract deployed by:", msg.sender);
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }
//agrego un comentario

    function ofertar(){

    }


}