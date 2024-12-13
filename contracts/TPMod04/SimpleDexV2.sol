// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleDEX is Ownable {
    address public tokenA;
    address public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);
    event Swap(address indexed user, address fromToken, uint256 inputAmount, uint256 outputAmount);

    constructor(address initialOwner, address _tokenA, address _tokenB) Ownable(initialOwner) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    /**
     * @dev Add liquidity to the pool. Only the owner can call this function.
     * @param amountA Amount of TokenA to add.
     * @param amountB Amount of TokenB to add.
     */
    function addLiquidity(uint256 amountA, uint256 amountB) payable external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than zero");

        // Transfer tokens from the owner to the contract
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "Transfer of TokenA failed");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB), "Transfer of TokenB failed");

        // Update reserves
        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    /**
     * @dev Swap TokenA for TokenB.
     * @param amountAIn Amount of TokenA to swap.
     */
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Amount must be greater than zero");

        // Calculate the amount of TokenB to send using the constant product formula
        uint256 amountBOut = (amountAIn * reserveB) / (reserveA + amountAIn);
        require(amountBOut > 0, "Insufficient output amount");

        // Transfer TokenA from user to contract and TokenB to user
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn), "Transfer of TokenA failed");
        require(IERC20(tokenB).transfer(msg.sender, amountBOut), "Transfer of TokenB failed");

        // Update reserves
        reserveA += amountAIn;
        reserveB -= amountBOut;

        emit Swap(msg.sender, tokenA, amountAIn, amountBOut);
    }

    /**
     * @dev Swap TokenB for TokenA.
     * @param amountBIn Amount of TokenB to swap.
     */
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Amount must be greater than zero");

        // Calculate the amount of TokenA to send using the constant product formula
        uint256 amountAOut = (amountBIn * reserveA) / (reserveB + amountBIn);
        require(amountAOut > 0, "Insufficient output amount");

        // Transfer TokenB from user to contract and TokenA to user
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn), "Transfer of TokenB failed");
        require(IERC20(tokenA).transfer(msg.sender, amountAOut), "Transfer of TokenA failed");

        // Update reserves
        reserveB += amountBIn;
        reserveA -= amountAOut;

        emit Swap(msg.sender, tokenB, amountBIn, amountAOut);
    }

    /**
     * @dev Remove liquidity from the pool. Only the owner can call this function.
     * @param amountA Amount of TokenA to withdraw.
     * @param amountB Amount of TokenB to withdraw.
     */
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA <= reserveA, "Insufficient TokenA reserve");
        require(amountB <= reserveB, "Insufficient TokenB reserve");

        // Update reserves
        reserveA -= amountA;
        reserveB -= amountB;

        // Transfer tokens back to the owner
        require(IERC20(tokenA).transfer(msg.sender, amountA), "Transfer of TokenA failed");
        require(IERC20(tokenB).transfer(msg.sender, amountB), "Transfer of TokenB failed");

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    /**
     * @dev Get the price of a token relative to the other.
     * @param _token Address of the token to get the price for.
     * @return price The relative price of the token.
     */
    function getPrice(address _token) external view returns (uint256 price) {
        if (_token == tokenA) {
            require(reserveB > 0, "No liquidity for TokenB");
            price = (reserveA * 1e18) / reserveB; // TokenA price in terms of TokenB
        } else if (_token == tokenB) {
            require(reserveA > 0, "No liquidity for TokenA");
            price = (reserveB * 1e18) / reserveA; // TokenB price in terms of TokenA
        } else {
            revert("Token not supported");
        }
    }
}

