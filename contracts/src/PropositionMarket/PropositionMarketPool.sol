// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Price} from "price/src/Price.sol";
import {SSTORE2} from "solady/src/utils/SSTORE2.sol";
import {LibClone} from "solady/src/utils/LibClone.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {UUPSUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeCastLib} from "solady/src/utils/SafeCastLib.sol";

import {IPropositionMarketFactory} from "./interfaces/IPropositionMarketFactory.sol";
import {IPropositionMarketPool_Def} from "./interfaces/IPropositionMarketPool.sol";
import {IPropositionMarketToken} from "./interfaces/IPropositionMarketToken.sol";

contract PropositionMarketPool is IPropositionMarketPool_Def, ReentrancyGuard, Initializable, UUPSUpgradeable {
    using Price for *;
    using LibClone for *;
    using LibString for *;
    using FixedPointMathLib for *;
    using SafeCastLib for uint256;
    using SafeCastLib for int256;

    uint256 public totalPlatformFee;
    bool public paused;
    uint256 public tvl;

    modifier onlyFactory() {
        if (getFactoryAddress() != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);
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

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        // any logic you want at deployment time, eg registering with factory
        __UUPSUpgradeable_init();
    }

    function buy(
        IPropositionMarketToken token,
        uint256 tokenAmount,
        uint256 usdtProvided,
        uint256 minTokenReceived,
        uint256 expireTimestamp
    ) external nonReentrant whenNotPaused timeCheck(expireTimestamp) tokenAmountCheck(usdtProvided) {
        // calculate price and amount
        (uint256 tokenSupply, uint256 supplyOther) = _getSupplies(address(token));

        uint256 usdtAmount = tokenSupply.getDeltaUSDT(supplyOther, int256(tokenAmount)).toUint256();
        uint256 tokenPrice = usdtAmount.divWad(tokenAmount);
        uint256 usdtNetAmount = usdtAmount.divWad(1 ether.rawSub(getPlatformFee()));

        // check usdt provided
        if (
            usdtNetAmount > usdtProvided ||
            (usdtProvided.rawSub(usdtNetAmount) > (usdtProvided / Price.DEFAULT_APPROXIMATION_PRECISION))
        ) {
            // Recalculate token amount and execution price by approximation. Need to exclude platform fee.
            (tokenAmount, tokenPrice) = Price.approximateExecutionPrice(
                tokenSupply,
                supplyOther,
                usdtProvided.mulWad(1 ether.rawSub(getPlatformFee()))
            );

            // check slippage
            if (tokenAmount < minTokenReceived) revert SlippageFailed(tokenAmount, minTokenReceived);

            // Update values with new token amount
            usdtAmount = Price.getDeltaUSDT(tokenSupply, supplyOther, int256(tokenAmount)).toUint256();
            usdtNetAmount = usdtAmount.divWad(1 ether.rawSub(getPlatformFee()));
        }

        // calculate platform fee
        totalPlatformFee += usdtNetAmount.rawSub(usdtAmount);

        // transfer usdt from sender and check if it's enough
        if (usdtNetAmount > usdtProvided) revert PaymentFailed();
        if (!getPayTokenAddress().transferFrom(msg.sender, address(this), usdtNetAmount)) revert PaymentFailed();

        // update tvl
        tvl += usdtAmount;

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
        // emit Swap(msg.sender, usdtNetAmount, tokenAmount, address(getPayTokenAddress()), address(token));
    }

    function sell(
        IPropositionMarketToken token,
        uint256 tokenAmount,
        uint256 minUsdtReceived,
        uint256 expireTimestamp
    ) external nonReentrant whenNotPaused timeCheck(expireTimestamp) tokenAmountCheck(tokenAmount) {
        // calculate price and amount
        (uint256 tokenSupply, uint256 supplyOther) = _getSupplies(address(token));
        int256 deltaUSDT = tokenSupply.getDeltaUSDT(supplyOther, -int256(tokenAmount));
        uint256 usdtAmount = (-deltaUSDT).toUint256();
        uint256 tokenPrice = usdtAmount.divWad(tokenAmount);

        // calculate platform fee
        uint256 platformFee = usdtAmount.mulWad(getPlatformFee());
        totalPlatformFee += platformFee;

        // check minimum received amount
        if (usdtAmount.rawSub(platformFee) < minUsdtReceived)
            revert SlippageFailed(usdtAmount.rawSub(platformFee), minUsdtReceived);

        // transfer token from sender and burn it
        token.burn(msg.sender, tokenAmount);

        // update tvl
        tvl -= usdtAmount;

        // transfer usdt to sender
        if (!getPayTokenAddress().transfer(msg.sender, usdtAmount.rawSub(platformFee))) revert PaymentFailed();

        // emit event
        IPropositionMarketFactory(getFactoryAddress()).emitEventTrade(
            address(token),
            msg.sender,
            -int256(tokenAmount),
            tokenPrice
        );
        // emit Swap(
        //     msg.sender,
        //     usdtAmount.rawSub(platformFee),
        //     tokenAmount,
        //     address(getPayTokenAddress()),
        //     address(token)
        // );
    }

    function collectPlatformFee(address receiver) external onlyFactory {
        if (totalPlatformFee == 0) revert InsufficientBalance();
        uint256 oldTotalPlatformFee = totalPlatformFee;

        totalPlatformFee = 0;

        if (!getPayTokenAddress().transfer(receiver, oldTotalPlatformFee)) revert PaymentFailed();
    }

    function pausedPool() external onlyFactory {
        if (paused) revert EnforcedPause();
        emit Paused(paused = !paused);
    }

    function getOptionListLength() public view returns (uint256 length) {
        bytes memory data = address(this).argsOnERC1967(0, 8);
        assembly {
            length := shr(192, mload(add(data, 32))) // 取低8字节
        }
        return length;
    }

    function getOptionList() public view returns (address[] memory) {
        unchecked {
            uint256 length = getOptionListLength();
            address dataPointer = _bytesToAddressExact(address(this).argsOnERC1967(8, 28));
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));

            address[] memory sliced = new address[](length);
            for (uint256 i = 0; i < length; ++i) {
                sliced[i] = fullList[i];
            }

            return sliced;
        }
    }

    function getFactoryAddress() public view returns (address) {
        unchecked {
            address dataPointer = _bytesToAddressExact(address(this).argsOnERC1967(8, 28));
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));
            return fullList[fullList.length - 3];
        }
    }

    function getPayTokenAddress() public view returns (IERC20) {
        unchecked {
            address dataPointer = _bytesToAddressExact(address(this).argsOnERC1967(8, 28));
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

    function getUsdtDelta(address token, int256 amountChanged) public view returns (int256) {
        (uint256 supply, uint256 supplyOther) = _getSupplies(token);
        return Price.getDeltaUSDT(supply, supplyOther, amountChanged);
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

    function getPoolTitle() public view returns (string memory) {
        unchecked {
            return _bytesToBytes32(address(this).argsOnERC1967(28, 60)).fromSmallString();
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyFactory {}

    function _mintAndTransfer(IPropositionMarketToken token, uint256 tokenAmount) internal {
        token.mint(msg.sender, tokenAmount);
        // if (!token.transfer(msg.sender, tokenAmount)) revert PaymentFailed();
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

    function _bytesToAddressExact(bytes memory data) internal pure returns (address result) {
        assembly {
            result := shr(96, mload(add(data, 32))) // shift right 96 bits = 12 bytes = keep low 20 bytes
        }
    }

    function _bytesToBytes32(bytes memory data) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(data, 32))
        }
    }
}
