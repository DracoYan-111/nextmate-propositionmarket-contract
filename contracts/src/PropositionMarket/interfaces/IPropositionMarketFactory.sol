// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IPropositionMarketToken {
    function transferOwnership(address newOwner) external;
}

interface IPropositionMarketFactory {
    event CreatePool(address indexed pool);
    event Trade(
        address indexed pool,
        address indexed token,
        address indexed trader,
        int256 tokenAmount,
        uint256 executionPrice
    );

    error InvalidInput(string[]);
}
