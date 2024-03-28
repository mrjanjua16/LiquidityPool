// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Lend is ReentrancyGuard
{
    uint256 public baseInterestRate=10;

    // Storage variables for deposit
    mapping(address => uint256) public userDeposits;

    // Borrowed amount tracking variables
    uint256 public totalBorrowed;
    mapping(address => uint256) userBorrow;

    // Borrow info
    struct BorrowInfo
    {
        uint256 amount;
        uint256 interestRate;
        uint256 startTime;
    }

    // Borrow information mapping with user
    mapping(address => BorrowInfo) public borrowed;

    constructor(){}

    event DepositMade(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount, uint256 interestRate, uint256 startTime);

    // Function to depsit Ether into the lending pool
    function deposit() public payable 
    {
        require(msg.value >0, "Deposit amount must be greater than zero");
        userDeposits[msg.sender] += msg.value;
        emit DepositMade(msg.sender, msg.value);
    }

    // Get Balance
    function getUserBalance(address user) public view returns(uint256)
    {
        return userDeposits[user];
    }

    // Borrow function with access control and security
    function borrow(uint256 amount) public payable nonReentrant
    {
        require(amount > 0, "Borrow amount must be greater than zero");
        require(address(this).balance >= amount, "Insufficient liquidity for borrowing");

        // Update user borrows and total borrows
        userBorrow[msg.sender] += amount;
        totalBorrowed += amount;

        // Calculate interest rate based on fixed base rate and time factor

        // Store borrow information
        borrowed[msg.sender] = BorrowInfo({amount: amount, interestRate: baseInterestRate, startTime: block.timestamp});

        emit Borrowed(msg.sender, amount, baseInterestRate, block.timestamp);
    }

    function repay() public payable nonReentrant
    {
        require(msg.value > 0, "Repayment amount must be greater than zero");

        // Update user borrows and total borrows
        userBorrow[msg.sender] -= msg.value;
        totalBorrowed -= msg.value;

        // Calculate accrued interest
        uint256 accruedInterest = calculateAccruedInterest(msg.sender);

        // Amount greater check
        require(userBorrow[msg.sender] >= msg.value + accruedInterest, "Repayment exceeds borrow amount");

        // Ensure repayment coveres borrow amount + accrued interest
        require(msg.value >= accruedInterest, "Insufficient funds for accrued interest");

        // Transfer excess funds back to user
        if(msg.value > accruedInterest)
        {
            payable(msg.sender).transfer(msg.value - accruedInterest);
        }
    }

    function calculateAccruedInterest(address user) public view returns(uint256)
    {
        BorrowInfo memory borrowInfo = borrowed[user];
        uint256 timeElapsed = block.timestamp - borrowInfo.startTime;
        uint256 interestAccrued = borrowInfo.amount * borrowInfo.interestRate + timeElapsed;
        return  interestAccrued;
    }
}