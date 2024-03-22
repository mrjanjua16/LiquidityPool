// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Escrow.sol";

contract LendingPool is ReentrancyGuard
{
    uint256 public baseInterestRate = 10;
    // Storage variables for deposit
    mapping (address => mapping(address => uint256)) public userDeposits;
    // Array of supported token addresses
    address[] public supportedTokens;
    // Array to track borrows
    mapping (address => mapping (address => uint256)) public userBorrows;

    // Storage Variables for collateral
    // Tracks user collateral for each token
    mapping(address => mapping(address => uint256)) public collateral; 

    // **Borrowed amount tracking variables**
    // Borrowed amount per token
    mapping(address => uint256) public totalBorrowedperToken;
    // Borrowed amount per user
    mapping(address => uint256) public totalBorrowedperUser;

    // Borrow info stuct
    struct BorrowInfo
    {
        uint256 amount;
        uint256 interestRate;
        uint256 startTime;
    }

    // Borrow information mapping with token and user
    mapping(address => mapping(address => BorrowInfo)) public borrowedToken;

    // References to other contracts - instances
    Escrow public escrow;
    
    constructor(Escrow _escrow)
    {
        escrow = _escrow;
    }

    event DepositMade(address indexed token, address indexed user, uint256 amount);
    event Borrowed(address indexed user, address indexed token, uint256 amount, uint256 interestRate, uint256 startTime);


    // Function to deposit funds into the lending pool
    function deposit(address token, uint256 amount) public
    {
        require(amount > 0, "Deposit amount must be greater than zero");
        // Transfers token from user to contract
        IERC20(token).transferFrom(msg.sender, address(this), amount); 
        userDeposits[token][msg.sender] += amount;
        emit DepositMade(token, msg.sender, amount);
    }

    // Function to retrieve user's balance for a specific token
    function getUserBalance(address user, address token) public view returns(uint256)
    {
        return userDeposits[token][user]; // Returns user's deposit amount for the token
    }   

    // Function with Access control and security
    function borrow(address token, uint256 amount) public nonReentrant
    {
        require(amount > 0, "Borrow amount must be greater than zero");
        require(isSufficientCollateral(msg.sender, token, amount), "Insufficient collateral");
        require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient liquidity for borrowing");

        // Update user borrows and total borrows
        userBorrows[token][msg.sender] += amount;
        totalBorrowedperToken[token] += amount;
        totalBorrowedperUser[msg.sender] += amount;

        // Interact with Escrow to lock collateral
        depositCollateral(token, msg.sender, calculateRequiredCollateral(amount));

        // Calculate interest rate based on fixed base rate and time factor
        uint256 timeFactor = block.timestamp;
        uint256 interestRate = baseInterestRate + timeFactor;

        // Store borrow information (borrow amount, interest rate) for user
        borrowedToken[msg.sender][token] = BorrowInfo({amount: amount, interestRate: interestRate, startTime: block.timestamp});

        emit Borrowed(msg.sender, token, amount, interestRate, block.timestamp);
    }

    function repay(address token, uint256 amount) public nonReentrant
    {
        require(amount > 0, "Repayment amount must be greater than zero");
        

        // Update user borrows and total borrows
        userBorrows[token][msg.sender] -= amount;
        totalBorrowedperToken[token] -= amount;
        totalBorrowedperUser[msg.sender] -= amount;

        // Calculate accrued interest
        uint256 accruedInterest = calculateAccruedInterest(token, msg.sender);

        // Amount greater check
        require(userBorrows[token][msg.sender] >= amount + accruedInterest, "Repayment amount exceeds borrow amount");

        // Amount less check
        // Ensure repayment covers borrow amount + accrued interest
        require(amount + accruedInterest >= msg.value, "Insufficient funds for repayment and accrued interest");

        // Transfer excess funds back to user
        if(amount + accruedInterest > msg.value)
        {
            payable(msg.sender).transfer(amount+accruedInterest - msg.value);
        }

        // Interact with Escrow to release collateral
    }

    function calculateAccruedInterest(address token, address user) public view returns (uint256) {
        BorrowInfo memory borrowInfo = borrowedToken[user][token];
        uint256 timeElapsed = block.timestamp - borrowInfo.startTime;  // Calculate time elapsed since borrow
        uint256 interestAccrued = borrowInfo.amount * borrowInfo.interestRate * timeElapsed / INTEREST_ACCUMULATION_TIME;
        return interestAccrued;
    }


    // Deposit Collateral
    function depositCollateral(address token, address borrower, uint256 amount) public{}

    function isSufficientCollateral(address user, address token, uint256 borrowAmount) public view returns(bool)
    {
        uint256 totalUserDeposists = 0;
        for(uint256 i=0; i<supportedTokens.length; i++)
        {
            totalUserDeposists += userDeposits[supportedTokens[i]][user];
        }
    

    }

    function calculateRequiredCollateral(uint256 borrowAmount) public pure returns(uint256)
    {
    // Implement logic to calculate minimum required collateral based on over-collateralization ratio (e.g., borrow amount * OVER_COLLATERALIZATION_RATIO)


    }

    // Withdraw Collateral
    function withdrawCollateral(address token, address borrower, uint256 amount) public {}

    function calculateInterestRate(address token, uint256 totalSupply, uint256 totalBorrows) public view returns (uint256) {
    // ... (Logic to define interest rate calculation based on supply and demand or other factors)
  }



}
