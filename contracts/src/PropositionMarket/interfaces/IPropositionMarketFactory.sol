// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IPropositionMarketToken {
    function initialize(address initialOwner, string memory name, string memory symbol) external;
}

interface IPropositionMarketFactory {
    error InvalidInput(string[]);
}
