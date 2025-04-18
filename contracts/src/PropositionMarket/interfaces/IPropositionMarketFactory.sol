// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IPropositionMarketToken {
    function transferOwnership(address newOwner) external;
}

interface IPropositionMarketFactory {
    error InvalidInput(string[]);

    event createPool(address indexed pool);
    event trade(
        address indexed pool,
        address indexed token,
        address indexed trader,
        int256 tokenAmount,
        uint256 executionPrice
    );
}
