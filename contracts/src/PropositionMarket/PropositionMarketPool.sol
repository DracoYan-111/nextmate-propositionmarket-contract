// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Price} from "price/src/Price.sol";
import {SSTORE2} from "solady/src/utils/SSTORE2.sol";
import {CWIA} from "solady/src/utils/legacy/CWIA.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";
import {IPropositionMarketToken, IPropositionMarketPool, IPropositionMarketFactory} from "./interfaces/IPropositionMarketPool.sol";

// TODO:增加pool版本
contract PropositionMarketPool is IPropositionMarketPool, CWIA {
    using Price for *;
    using LibString for *;
    using FixedPointMathLib for *;

    uint256 public totalPlatformFee;
    bool public paused;

    modifier onlyManager() {
        if (getManagerAddress() != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);
        _;
    }
    modifier whenNotPaused() {
        if (!paused) revert EnforcedPause();
        _;
    }

    function getOptionListLength() external pure returns (uint256) {
        return _getArgUint64(0);
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

    function getPlatformFee() public view returns (uint256) {
        return IPropositionMarketFactory(getFactoryAddress()).getPlatformFee();
    }

    function getFeeRecipient() external view returns (address) {
        return IPropositionMarketFactory(getFactoryAddress()).getFeeRecipient();
    }

    function _getSupplies(address token) internal view returns (uint256 supply, uint256 supplyOther) {
        supply = IERC20(token).totalSupply();
        address[] memory optionList = getOptionList();
        for (uint256 i = 0; i < optionList.length; i++) {
            if (optionList[i] != token) {
                supplyOther += IERC20(optionList[i]).totalSupply();
            }
        }
    }

    function getSpotPrice(address token) public view returns (uint256) {
        (uint256 supply, uint256 supplyOther) = _getSupplies(token);
        return Price.getSpotPrice(supply, supplyOther);
    }

    function calculateSpotPrice(uint256 supply, uint256 supplyOther) external pure returns (uint256) {
        return Price.getSpotPrice(supply, supplyOther);
    }

    function getExecutionPrice(address token, int256 amountChanged) public view returns (uint256) {
        (uint256 supply, uint256 supplyOther) = _getSupplies(token);
        return Price.getExecutionPrice(supply, supplyOther, amountChanged);
    }

    function calculateExecutionPrice(
        uint256 supply,
        uint256 supplyOther,
        int256 amountChanged
    ) external pure returns (uint256) {
        return Price.getExecutionPrice(supply, supplyOther, amountChanged);
    }

    function getApproximatePrice(
        address token,
        uint256 usdtAmount
    ) public view returns (uint256 tokenAmount, uint256 avgPrice) {
        (uint256 supply, uint256 supplyOther) = _getSupplies(token);
        (tokenAmount, avgPrice) = Price.approximateExecutionPrice(supply, supplyOther, usdtAmount);
    }

    function buy(
        IPropositionMarketToken token,
        uint256 tokenAmount,
        uint256 expireTimestamp
    ) external returns (uint256) {
        if (expireTimestamp < block.timestamp) revert TimeoutProhibition();

        address[] memory optionList = getOptionList();

        uint256 supplyIndex = 0;
        uint256 supplyOther = 0;
        for (uint256 i; i < optionList.length; ++i) {
            if (optionList[i] == address(token)) {
                supplyIndex = i;
                continue;
            }
            supplyOther += IPropositionMarketToken(optionList[i]).totalSupply();
        }

        uint256 tokenPrice = IPropositionMarketToken(optionList[supplyIndex]).totalSupply().getSpotPrice(supplyOther);

        uint256 usdtAmount = tokenPrice.mulWad(tokenAmount);

        uint256 platformFee = usdtAmount.mulWad(getPlatformFee());
        totalPlatformFee += platformFee;

        uint256 usdtNetAmount = usdtAmount.rawAdd(platformFee);

        if (!getPayTokenAddress().transferFrom(msg.sender, address(this), usdtNetAmount)) revert PaymentFailed();

        token.mint(msg.sender, tokenAmount);

        emit BuyToken(msg.sender, tokenAmount);

        return tokenAmount;
    }

    function buy(
        IPropositionMarketToken token,
        uint256 tokenAmount, // 估值 10 Token 100
        uint256 usdtAmount, // 10
        uint256 minTokenReceived,
        uint256 expireTimestamp
    ) external returns (uint256) {
        if (expireTimestamp < block.timestamp) revert TimeoutProhibition();

        address[] memory optionList = getOptionList();

        uint256 supplyIndex = 0;
        uint256 supplyOther = 0;
        for (uint256 i; i < optionList.length; ++i) {
            if (optionList[i] == address(token)) {
                supplyIndex = i;
                continue;
            }
            supplyOther += IPropositionMarketToken(optionList[i]).totalSupply();
        }

        if (!getPayTokenAddress().transferFrom(msg.sender, address(this), usdtAmount)) revert PaymentFailed();

        uint256 platformFee = usdtAmount.mulWad(getPlatformFee());
        totalPlatformFee += platformFee;

        uint256 usdtNetAmount = usdtAmount.rawSub(platformFee);

        uint256 tokenPrice = IPropositionMarketToken(optionList[supplyIndex]).totalSupply().getSpotPrice(supplyOther);

        uint256 tokenNetAmount = usdtNetAmount.divWad(tokenPrice);

        if (tokenNetAmount < minTokenReceived) revert InsufficientOutputAmount(tokenNetAmount, minTokenReceived);

        token.mint(msg.sender, tokenNetAmount);

        emit BuyToken(msg.sender, tokenNetAmount);
        return tokenNetAmount;
    }

    function sell(
        IPropositionMarketToken token,
        uint256 tokenAmount,
        uint256 minUsdtReceived,
        uint256 expireTimestamp
    ) external returns (uint256) {
        if (expireTimestamp < block.timestamp) revert TimeoutProhibition();

        address[] memory optionList = getOptionList();

        uint256 supplyIndex = 0;
        uint256 supplyOther = 0;
        for (uint256 i; i < optionList.length; ++i) {
            if (optionList[i] == address(token)) {
                supplyIndex = i;
                continue;
            }
            supplyOther += IPropositionMarketToken(optionList[i]).totalSupply();
        }

        token.burn(msg.sender, tokenAmount);

        uint256 tokenPrice = IPropositionMarketToken(optionList[supplyIndex]).totalSupply().getSpotPrice(supplyOther);

        uint256 usdtAmount = tokenPrice.mulWad(tokenAmount);

        uint256 platformFee = usdtAmount.mulWad(getPlatformFee());
        totalPlatformFee += platformFee;

        uint256 usdtNetAmount = usdtAmount.rawSub(platformFee);

        if (usdtNetAmount < minUsdtReceived) revert InsufficientOutputAmount(usdtNetAmount, minUsdtReceived);

        if (!getPayTokenAddress().transfer(msg.sender, usdtNetAmount)) revert PaymentFailed();

        emit SellToken(msg.sender, tokenAmount);

        return usdtNetAmount;
    }

    function receivePlatformFee(address receiver) external onlyManager {
        if (totalPlatformFee == 0) revert InsufficientBalance();
        totalPlatformFee = 0;

        if (!getPayTokenAddress().transfer(receiver, totalPlatformFee)) revert PaymentFailed();
    }

    function pausedPool() external onlyManager {
        if (paused) revert EnforcedPause();
        emit Paused(paused = !paused);
    }
}
