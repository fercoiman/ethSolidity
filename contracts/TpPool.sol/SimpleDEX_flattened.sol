
// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: contracts/TpPool.sol/SimpleDEX.sol


//pragma solidity ^0.8.0;
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


contract SimpleDEX {
    address public tokenA;
    address public tokenB;
    uint256 public totalA; //Total de tokenA
    uint256 public totalB; //Total de tokenB
    address public owner;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event TokensSwapped(address indexed user, address fromToken, uint256 inputAmount, uint256 outputAmount);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);
    

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

        totalA += amountA;
        totalB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }
    // Swap de TokenA por TokenB
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Amount must be greater than 0");
        uint256 amountBOut = (amountAIn * totalB) / (totalA + amountAIn);
        require(amountBOut > 0, "Not Enough output amount");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);
        IERC20(tokenB).transfer(msg.sender, amountBOut);

        totalA += amountAIn;
        totalB -= amountBOut;

        emit TokensSwapped(msg.sender, tokenA, amountAIn, amountBOut);
    }
    // Swap de TokenB por TokenA
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Amount must be greater than 0");
        uint256 amountAOut = (amountBIn * totalA) / (totalB + amountBIn);
        require(amountAOut > 0, "Not Enough output amount");

        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);
        IERC20(tokenA).transfer(msg.sender, amountAOut);

        totalB += amountBIn;
        totalA -= amountAOut;

        emit TokensSwapped(msg.sender, tokenB, amountBIn, amountAOut);
    }

    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA <= totalA, "Not Enough TokenA total");
        require(amountB <= totalB, "Not Enough TokenB total");

        totalA -= amountA;
        totalB -= amountB;

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    function getPrice(address _token) external view returns (uint256 price) {
        if (_token == tokenA) {
            require(totalB > 0, "No liquidity for TokenB");
            price = 10**18*(totalA / totalB);
        } else if (_token == tokenB) {
            require(totalA > 0, "No liquidity for TokenA");
            price = 10**18*(totalB / totalA);
        } else {
            revert("Token not supported");
        }
    }
}
