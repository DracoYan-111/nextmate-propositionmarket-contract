// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IPropositionMarketToken {
    function transferOwnership(address newOwner) external;
}

interface IPropositionMarketFactory {
    error InvalidInput(string[]);
}
