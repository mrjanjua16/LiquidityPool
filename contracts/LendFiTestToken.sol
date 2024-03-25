// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LendFiTestToken is ERC20, Ownable {
  // Define a constant for the maximum supply
  uint256 public constant MAX_SUPPLY = 10000; // 1 Billion tokens

  // State variable to track total supply
  uint256 public Supply;

  constructor() ERC20("LendFi Test Token", "LFT") Ownable(msg.sender) {
    Supply = 1000; // Set total supply during deployment
    _mint(msg.sender, Supply); // Mint the initial supply to the deployer
  }

  // Minting function with access control
  function mint(address to, uint256 amount) public onlyOwner {
    require(Supply + amount <= MAX_SUPPLY, "Total supply exceeded");
    _mint(to, amount);
    Supply += amount;
  }

  // Optional burning function
  function burn(uint256 amount) public {
    _burn(msg.sender, amount);
  }
}
