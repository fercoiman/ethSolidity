// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleDEX is Ownable {
    address public tokenA;
    address public tokenB;
    uint256 public totalA; // Total de tokenA
    uint256 public totalB; // Total de tokenB

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event TokensSwapped(address indexed user, address fromToken, uint256 inputAmount, uint256 outputAmount);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);

    constructor(address initialOwner, address _tokenA, address _tokenB) Ownable(initialOwner) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // Agregar Liquidez
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
            price = 10**18 * (totalA / totalB);
        } else if (_token == tokenB) {
            require(totalA > 0, "No liquidity for TokenA");
            price = 10**18 * (totalB / totalA);
        } else {
            revert("Token not supported");
        }
    }
}

