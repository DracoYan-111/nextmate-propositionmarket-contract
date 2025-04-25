// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IPropositionMarketPool_Def {
    event Paused(bool);
    event Swap(
        address indexed sender,
        uint256 amountIn,
        uint256 amountOut,
        address indexed tokenIn,
        address indexed tokenOut
    );

    error EnforcedPause();
    error PaymentFailed();
    error TimeoutProhibition();
    error InsufficientBalance();
    error OwnableUnauthorizedAccount(address);
    error SlippageFailed(uint256, uint256);
    error InvalidToken();
    error ZeroQuantityError();
}

interface IPropositionMarketPool is IPropositionMarketPool_Def {
    function upgradeToAndCall(address, bytes memory) external payable;

    function collectPlatformFee(address receiver) external;

    function initialize() external;

    function pausedPool() external;
}
