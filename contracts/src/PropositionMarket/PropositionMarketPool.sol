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

    function buyOption(IPropositionMarketToken supplyToken, uint256 supplyTokenAmount, uint256 timestamp) external {
        if (timestamp < block.timestamp) {}
        IPropositionMarketToken(supplyToken).mint(msg.sender, 100 ether);
        getPayTokenAddress().transferFrom(msg.sender, address(this), 1 ether);
        if (supplyTokenAmount < 100 ether) {}
    }

    function buy(
        IPropositionMarketToken token,
        uint256 tokenAmount, // 估值 10 Token 100
        uint256 usdtAmount, // 10
        uint256 minTokenRecived,
        uint256 expireTimestamp
    ) external {
        if (expireTimestamp < block.timestamp) {}
        IPropositionMarketToken(token).mint(msg.sender, 1 ether);
        getPayTokenAddress().transferFrom(msg.sender, address(this), usdtAmount);
        if (minTokenRecived < tokenAmount) {}
    }

    function sell(
        IPropositionMarketToken token,
        uint256 tokenAmount,
        uint256 minUsdtReceived,
        uint256 expireTimestamp
    ) external {
        if (expireTimestamp < block.timestamp) {}
        IPropositionMarketToken(token).burn(msg.sender, tokenAmount);
        getPayTokenAddress().transfer(msg.sender, minUsdtReceived);
    }

    function receivePlatformFee(address receiver) external onlyManager {
        if (totalPlatformFee == 0) revert InsufficientBalance();
        totalPlatformFee = 0;
        getPayTokenAddress().transfer(receiver, totalPlatformFee);
    }

    function pausedPool() external onlyManager {
        if (paused) revert EnforcedPause();
        emit Paused(paused = !paused);
    }
}
