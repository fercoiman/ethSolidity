// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*Una "liquidity pool" o reserva de liquidez es un conjunto de fondos bloqueados 
en depósito en un "smart contract". 
Las reservas de liquidez se emplean para facilitar el trading*/

/*proveedores de liquidez (LPs) aportan un valor equivalente de dos tokens 
en una reserva (pool) para así crear un mercado. A cambio de aportar sus fondos, 
ganarán comisiones de trading a partir de los trades que tengan lugar en su "pool" 
o reserva, de manera proporcional a su participación en la liquidez total.*/

/* los creadores de mercado son entidades que facilitan la negociación 
al estar siempre dispuestos a comprar o vender un activo en particular. 
Al hacer eso, proporcionan liquidez, por lo que los usuarios siempre pueden operar
 y no tienen que esperar a que aparezca otra contraparte.*/

 /*En su forma básica, un solo grupo de liquidez contiene 2 tokens y cada grupo 
 crea un nuevo mercado para ese par de tokens en particular. DAI / ETH */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleDEX {
    address public tokenA;
    address public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;
    address public owner;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);
    event Swap(address indexed user, address fromToken, uint256 inputAmount, uint256 outputAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        owner = msg.sender;
    }

    //Agregar Liquidez
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "Transfer of TokenA failed");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB), "Transfer of TokenB failed");

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }
    // Swap de TokenA por TokenB
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Amount must be greater than 0");
        uint256 amountBOut = (amountAIn * reserveB) / (reserveA + amountAIn);
        require(amountBOut > 0, "Insufficient output amount");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);
        IERC20(tokenB).transfer(msg.sender, amountBOut);

        reserveA += amountAIn;
        reserveB -= amountBOut;

        emit Swap(msg.sender, tokenA, amountAIn, amountBOut);
    }
    // Swap de TokenB por TokenA
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Amount must be greater than 0");
        uint256 amountAOut = (amountBIn * reserveA) / (reserveB + amountBIn);
        require(amountAOut > 0, "Insufficient output amount");

        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);
        IERC20(tokenA).transfer(msg.sender, amountAOut);

        reserveB += amountBIn;
        reserveA -= amountAOut;

        emit Swap(msg.sender, tokenB, amountBIn, amountAOut);
    }

    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA <= reserveA, "Insufficient TokenA reserve");
        require(amountB <= reserveB, "Insufficient TokenB reserve");

        reserveA -= amountA;
        reserveB -= amountB;

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    function getPrice(address _token) external view returns (uint256 price) {
        if (_token == tokenA) {
            require(reserveB > 0, "No liquidity for TokenB");
            price = reserveA / reserveB;
        } else if (_token == tokenB) {
            require(reserveA > 0, "No liquidity for TokenA");
            price = reserveB / reserveA;
        } else {
            revert("Token not supported");
        }
    }
}
