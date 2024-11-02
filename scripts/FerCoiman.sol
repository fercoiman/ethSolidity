// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;

contract FerCoimanStorageFirstTest{
    string mensaje;
    function obtenerMensaje() public view returns(string memory){
        return mensaje;
    }

    function establecerMensaje(string calldata _mensaje) public{
        mensaje = _mensaje;
    }
}