// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPropositionMarketPool {
    event Paused(bool);
    event BuyToken(address from, uint256 amount);
    event SellToken(address from, uint256 amount);

    error EnforcedPause();
    error PaymentFailed();
    error TimeoutProhibition();
    error InsufficientBalance();
    error OwnableUnauthorizedAccount(address);
    error InsufficientOutputAmount(uint256, uint256);
}

interface IPropositionMarketFactory {
    function getPlatformFee() external view returns (uint256);

    function getFeeRecipient() external view returns (address);
}

interface IPropositionMarketToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;
}
