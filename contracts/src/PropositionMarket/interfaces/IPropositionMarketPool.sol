// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IPropositionMarketPool {
    event Paused(bool);

    error EnforcedPause();
    error InsufficientBalance();
    error OwnableUnauthorizedAccount(address);
}

interface IPropositionMarketFactory {
    function getPlatformFee() external view returns (uint256);

    function getFeeRecipient() external view returns (address);
}
