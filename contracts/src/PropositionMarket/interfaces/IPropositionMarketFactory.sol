// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IPropositionMarketFactory_Def {
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

interface IPropositionMarketFactory is IPropositionMarketFactory_Def {
    function emitEventTrade(address token, address trader, int256 tokenAmount, uint256 executionPrice) external;

    function getPlatformFee() external view returns (uint256);

    function getFeeRecipient() external view returns (address);
}
