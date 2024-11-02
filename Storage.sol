// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;

contract Storage{
    string mensaje;
    function getMensaje() public view returns(string memory){
        return mensaje;
    }

    function setMensaje(string calldata _mensaje) public{
        mensaje = _mensaje;
    }
}