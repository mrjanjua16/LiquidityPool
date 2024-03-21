// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Escrow.sol";

contract LendingPool is ReentrancyGuard
{
    // Storage variables for deposit
    
    // Tracks user deposits for each token

    // Array of supported token addresses

    // References to other contracts

    constructor() public {}

    function deposit(address token, uint256 amount) public {}

    function borrow(address token, uint256 amount) public {}

    function repay(address token, uint256 amount) public {}
}
