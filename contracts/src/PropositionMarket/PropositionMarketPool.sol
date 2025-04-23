// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Price} from "price/src/Price.sol";
import {SSTORE2} from "solady/src/utils/SSTORE2.sol";
import {CWIA} from "solady/src/utils/legacy/CWIA.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IPropositionMarketToken, IPropositionMarketPool, IPropositionMarketFactory} from "./interfaces/IPropositionMarketPool.sol";

contract PropositionMarketPool is IPropositionMarketPool, CWIA, ReentrancyGuard {
    using Price for *;
    using LibString for *;
    using FixedPointMathLib for *;

    uint256 public totalPlatformFee;
    bool public paused;
    mapping(address => uint256) public optionTvl;

    modifier onlyManager() {
        if (getManagerAddress() != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);
        _;
    }
    modifier whenNotPaused() {
        if (paused) revert EnforcedPause();
        _;
    }

    modifier timeCheck(uint256 expireTimestamp) {
        if (expireTimestamp < block.timestamp) revert TimeoutProhibition();
        _;
    }

    modifier tokenAmountCheck(uint256 tokenAmount) {
        if (tokenAmount == 0) revert ZeroQuantityError();
        _;
    }

    function buy(
        IPropositionMarketToken token,
        uint256 tokenAmount,
        uint256 maxUsdtProvided,
        uint256 expireTimestamp
    ) external nonReentrant whenNotPaused timeCheck(expireTimestamp) tokenAmountCheck(tokenAmount) returns (uint256) {
        // calculate price and amount
        (uint256 tokenSupply, uint256 supplyOther) = _getSupplies(address(token));
        uint256 tokenPrice = Price.getExecutionPrice(tokenSupply, supplyOther, int256(tokenAmount));
        uint256 usdtAmount = tokenPrice.mulWad(tokenAmount);

        // calculate platform fee
        uint256 platformFee = usdtAmount.mulWad(getPlatformFee());
        totalPlatformFee += platformFee;

        // transfer usdt from sender
        uint256 usdtNetAmount = usdtAmount.rawAdd(platformFee);
        if (usdtNetAmount > maxUsdtProvided) revert SlippageFailed(usdtNetAmount, maxUsdtProvided);
        if (!getPayTokenAddress().transferFrom(msg.sender, address(this), usdtNetAmount)) revert PaymentFailed();

        // update tvl
        optionTvl[address(token)] += usdtNetAmount;

        // mint and transfer token to sender
        _mintAndTransfer(token, tokenAmount);

        // emit event
        IPropositionMarketFactory(getFactoryAddress()).emitEventTrade(
            address(token),
            msg.sender,
            int256(tokenAmount),
            tokenPrice
        );

        return tokenAmount;
    }

    function buy(
        IPropositionMarketToken token,
        uint256 tokenAmount,
        uint256 usdtProvided,
        uint256 minTokenReceived,
        uint256 expireTimestamp
    ) external nonReentrant whenNotPaused timeCheck(expireTimestamp) tokenAmountCheck(usdtProvided) returns (uint256) {
        // calculate price and amount
        (uint256 tokenSupply, uint256 supplyOther) = _getSupplies(address(token));

        uint256 tokenPrice = tokenSupply.getExecutionPrice(supplyOther, int256(tokenAmount));
        uint256 usdtAmount = tokenPrice.mulWad(tokenAmount);
        uint256 usdtNetAmount = usdtAmount.divWad(1 ether.rawSub(getPlatformFee()));

        // check usdt provided
        if (
            usdtNetAmount > usdtProvided ||
            (usdtProvided.rawSub(usdtNetAmount) > (usdtProvided / Price.DEFAULT_APPROXIMATION_PRECISION))
        ) {
            // Recalculate token amount and execution price by approximation
            (uint256 newTokenAmount, uint256 executionPrice) = Price.approximateExecutionPrice(
                tokenSupply,
                supplyOther,
                usdtAmount
            );

            // check slippage
            if (newTokenAmount < minTokenReceived) revert SlippageFailed(newTokenAmount, minTokenReceived);

            // Update values with new token amount
            tokenAmount = newTokenAmount;
            tokenPrice = executionPrice;
            usdtAmount = tokenPrice.mulWad(tokenAmount);
            usdtNetAmount = usdtAmount.divWad(1 ether.rawSub(getPlatformFee()));
        }

        // calculate platform fee
        totalPlatformFee += usdtNetAmount.rawSub(usdtAmount);

        // transfer usdt from sender
        if (!getPayTokenAddress().transferFrom(msg.sender, address(this), usdtNetAmount)) revert PaymentFailed();

        // update tvl
        optionTvl[address(token)] += usdtAmount;

        // mint and transfer token to sender
        if (tokenAmount < minTokenReceived) revert SlippageFailed(tokenAmount, minTokenReceived);

        _mintAndTransfer(token, tokenAmount);

        // emit event
        IPropositionMarketFactory(getFactoryAddress()).emitEventTrade(
            address(token),
            msg.sender,
            int256(tokenAmount),
            tokenPrice
        );

        return tokenAmount;
    }

    function sell(
        IPropositionMarketToken token,
        uint256 tokenAmount,
        uint256 minUsdtReceived,
        uint256 expireTimestamp
    ) external nonReentrant whenNotPaused timeCheck(expireTimestamp) tokenAmountCheck(tokenAmount) returns (uint256) {
        // calculate price and amount
        (uint256 tokenSupply, uint256 supplyOther) = _getSupplies(address(token));
        uint256 tokenPrice = tokenSupply.getExecutionPrice(supplyOther, -int256(tokenAmount));
        uint256 usdtAmount = tokenPrice.mulWad(tokenAmount);

        // calculate platform fee
        uint256 platformFee = usdtAmount.mulWad(getPlatformFee());
        totalPlatformFee += platformFee;
        uint256 usdtNetAmount = usdtAmount.rawSub(platformFee);

        // check minimum received amount
        if (usdtNetAmount < minUsdtReceived) revert SlippageFailed(usdtNetAmount, minUsdtReceived);

        // transfer token from sender and burn it
        token.burn(msg.sender, tokenAmount);

        // update tvl
        optionTvl[address(token)] -= usdtNetAmount;

        // transfer usdt to sender
        if (!getPayTokenAddress().transfer(msg.sender, usdtNetAmount)) revert PaymentFailed();

        // emit event
        IPropositionMarketFactory(getFactoryAddress()).emitEventTrade(
            address(token),
            msg.sender,
            -int256(tokenAmount),
            tokenPrice
        );

        return usdtNetAmount;
    }

    function receivePlatformFee(address receiver) external onlyManager {
        if (totalPlatformFee == 0) revert InsufficientBalance();
        uint256 oldTotalPlatformFee = totalPlatformFee;

        totalPlatformFee = 0;

        if (!getPayTokenAddress().transfer(receiver, oldTotalPlatformFee)) revert PaymentFailed();
    }

    function pausedPool() external onlyManager {
        if (paused) revert EnforcedPause();
        emit Paused(paused = !paused);
    }

    function getFeeRecipient() external view returns (address) {
        return IPropositionMarketFactory(getFactoryAddress()).getFeeRecipient();
    }

    function getOptionListLength() external pure returns (uint256) {
        return _getArgUint64(0);
    }

    function calculateSpotPrice(uint256 supply, uint256 supplyOther) external pure returns (uint256) {
        return Price.getSpotPrice(supply, supplyOther);
    }

    function calculateExecutionPrice(
        uint256 supply,
        uint256 supplyOther,
        int256 amountChanged
    ) external pure returns (uint256) {
        return Price.getExecutionPrice(supply, supplyOther, amountChanged);
    }

    function getOptionList() public view returns (address[] memory) {
        unchecked {
            address dataPointer = _getArgAddress(8);
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));

            address[] memory sliced = new address[](_getArgUint64(0));
            for (uint256 i = 0; i < _getArgUint64(0); ++i) {
                sliced[i] = fullList[i];
            }

            return sliced;
        }
    }

    function getFactoryAddress() public view returns (address) {
        unchecked {
            address dataPointer = _getArgAddress(8);
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));
            return fullList[fullList.length - 3];
        }
    }

    function getManagerAddress() public view returns (address) {
        unchecked {
            address dataPointer = _getArgAddress(8);
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));
            return fullList[fullList.length - 2];
        }
    }

    function getPayTokenAddress() public view returns (IERC20) {
        unchecked {
            address dataPointer = _getArgAddress(8);
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));
            return IERC20(fullList[fullList.length - 1]);
        }
    }

    function getPlatformFee() public view returns (uint256) {
        return IPropositionMarketFactory(getFactoryAddress()).getPlatformFee();
    }

    function getSpotPrice(address token) public view returns (uint256) {
        (uint256 supply, uint256 supplyOther) = _getSupplies(token);
        return Price.getSpotPrice(supply, supplyOther);
    }

    function getExecutionPrice(address token, int256 amountChanged) public view returns (uint256) {
        (uint256 supply, uint256 supplyOther) = _getSupplies(token);
        return Price.getExecutionPrice(supply, supplyOther, amountChanged);
    }

    function getApproximatePrice(
        address token,
        uint256 usdtAmount,
        uint256 precision,
        uint256 maxIteration
    ) public view returns (uint256 tokenAmount, uint256 avgPrice) {
        (uint256 supply, uint256 supplyOther) = _getSupplies(token);
        (tokenAmount, avgPrice) = Price.approximateExecutionPrice(
            supply,
            supplyOther,
            usdtAmount,
            precision,
            maxIteration
        );
    }

    function getApproximatePrice(
        address token,
        uint256 usdtAmount
    ) public view returns (uint256 tokenAmount, uint256 avgPrice) {
        (uint256 supply, uint256 supplyOther) = _getSupplies(token);
        (tokenAmount, avgPrice) = Price.approximateExecutionPrice(
            supply,
            supplyOther,
            usdtAmount,
            Price.DEFAULT_APPROXIMATION_PRECISION,
            Price.DEFAULT_MAX_ITERATIONS
        );
    }

    function getPoolTitle() public pure returns (string memory) {
        unchecked {
            return _getArgBytes32(28).fromSmallString();
        }
    }

    function getPoolVersion() public pure returns (string memory) {
        unchecked {
            return _getArgBytes32(60).fromSmallString();
        }
    }

    function _mintAndTransfer(IPropositionMarketToken token, uint256 tokenAmount) internal {
        token.mint(address(this), tokenAmount);
        if (!token.transfer(msg.sender, tokenAmount)) revert PaymentFailed();
    }

    function _getSupplies(address token) internal view returns (uint256 supply, uint256 supplyOther) {
        supply = IERC20(token).totalSupply();
        address[] memory optionList = getOptionList();
        bool find = false;

        for (uint256 i = 0; i < optionList.length; ++i) {
            if (optionList[i] != token) {
                supplyOther += IERC20(optionList[i]).totalSupply();
            } else {
                find = true;
            }
        }

        if (!find) revert InvalidToken();
    }
}
