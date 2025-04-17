// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {FixedPointMathLib} from "../../solady/src/utils/FixedPointMathLib.sol";
import {SafeCastLib} from "../../solady/src/utils/SafeCastLib.sol";

/**
 * @title Price Library
 * @notice Implements the bonding curve price calculations for the prediction market
 *
 * The library implements two main price formulas:
 *
 * 1. Spot Price Formula:
 *    P(supply) = pBase + supply / (supplyTotal + m) + k * sqrt(supply)
 *    Where:
 *    - pBase: Base price
 *    - supply: Current token supply
 *    - supplyTotal: Total supply of both tokens (supply + supplyOther)
 *    - m: Adjustment coefficient
 *    - k: Non-linear factor
 *
 * 2. Average Price Formula:
 *    avgPrice = [pBase * deltaSupply + (newSupply - supply - c * ln((newSupply + c)/(supply + c))) + (2/3) * k * (newSupply^(3/2) - supply^(3/2))] / deltaSupply
 *    Where:
 *    - deltaSupply: Change in token supply
 *    - supply: Initial supply
 *    - newSupply: Final supply (supply + deltaSupply)
 *    - c = Other token supply + m
 */
library Price {
    using FixedPointMathLib for *;
    using SafeCastLib for uint256;
    using SafeCastLib for int256;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Base price of the token (18 decimals)
    uint256 public constant pBase = 0.1 ether;

    /// @notice Adjustment coefficient to control the impact of total supply (18 decimals)
    uint256 public constant m = 1000 ether;

    /// @notice Non-linear factor for the square root term (18 decimals)
    uint256 public constant k = 0.005 ether;

    /// @notice Conversion factor from token to USDT decimals
    /// uint256 public constant TOKEN_TO_USDT = 1e12; // 18 - 6 = 12

    /// @notice Maximum number of iterations for the binary search
    uint256 public constant MAX_ITERATIONS = 20;

    /// @notice Approximation precision for the binary search
    uint256 public constant APPROXIMATION_PRECISION = 1e3;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    error NegativePrice(int256 price);
    error InsufficientSupply(int256 supply);
    error ApproximationFailed();
    error ZeroSupplyChange();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        PRICE FORMULAS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    /**
     * @notice Calculates the spot price based on current token supplies
     * @param supply Current token supply (18 decimals)
     * @param supplyOther Supply of the paired token (18 decimals)
     * @return price The calculated spot price in USDT (6 decimals)
     * @dev Implements P(supply) = pBase + supply / (supplyTotal + m) + k * sqrt(supply)
     */
    function getSpotPrice(uint256 supply, uint256 supplyOther) public pure returns (uint256) {
        uint256 supplyTotal = supply + supplyOther;
        uint256 denominator = supplyTotal + m;

        // Calculate linear term: supply / (supplyTotal + m)
        uint256 linearTerm = supply.divWad(denominator);

        // Calculate square root term: k * sqrt(supply)
        uint256 sqrtTerm = k.mulWad(supply.sqrtWad());

        uint256 price = pBase + linearTerm + sqrtTerm;
        return price; /// TOKEN_TO_USDT;
    }

    /**
     * @notice Calculates the average price for a given change in token supply
     * @param supply Initial token supply (18 decimals)
     * @param supplyOther Supply of the paired token (18 decimals)
     * @param deltaSupply Change in token supply (18 decimals), positive for buying, negative for selling
     * @return price The calculated average price in USDT (6 decimals)
     * @dev Implements the integral formula for average price calculation
     */
    function getExecutionPrice(uint256 supply, uint256 supplyOther, int256 deltaSupply) public pure returns (uint256) {
        // condition check
        if (deltaSupply == 0) {
            revert ZeroSupplyChange();
        }
        if (supply.toInt256() + deltaSupply < 0) {
            revert InsufficientSupply(supply.toInt256() + deltaSupply);
        }

        uint256 newSupply = deltaSupply > 0 ? supply + deltaSupply.toUint256() : supply - (-deltaSupply).toUint256();
        uint256 c = supplyOther + m;

        // Calculate ln((newSupply + c)/(supply + c))
        uint256 ratio = (newSupply + c).divWad(supply + c);

        int256 lnTerm = ratio.toInt256().lnWad();

        // Calculate integral term: newSupply - supply - c * ln((newSupply + c)/(supply + c))
        int256 integralTerm = newSupply.toInt256() - supply.toInt256() - c.toInt256().sMulWad(lnTerm);

        // Calculate square root integral term: (2/3) * k * (newSupply^(3/2) - supply^(3/2))
        int256 sqrtIntegral = (2 * k).toInt256().sMulWad(
            (newSupply.sqrtWad().mulWad(newSupply).toInt256() - supply.sqrtWad().mulWad(supply).toInt256()) / 3
        );

        // Calculate final average price
        int256 price = (pBase.toInt256().sMulWad(deltaSupply) + integralTerm + sqrtIntegral).sDivWad(deltaSupply);
        if (price < 0) {
            revert NegativePrice(price);
        }

        // Convert final price from 18 decimals to 6 decimals USDT
        return price.toUint256(); // / TOKEN_TO_USDT;
    }

    /**
     * @notice 计算给定USDT数量可以购买的token数量和平均价格
     * @param supply 当前token供应量 (18 decimals)
     * @param supplyOther 配对token的供应量 (18 decimals)
     * @param usdtAmount 用户提供的USDT数量 (已经是6 decimals)
     * @return tokenAmount 计算出的token数量 (18 decimals)
     * @return avgPrice 平均价格 (6 decimals)
     * @dev 使用二分法结合getAveragePrice函数计算
     */
    function approximateExecutionPrice(
        uint256 supply,
        uint256 supplyOther,
        uint256 usdtAmount
    ) public pure returns (uint256 tokenAmount, uint256 avgPrice) {
        // 计算新的供应量 (买入情况，只会增加)
        uint256 spotPrice = getSpotPrice(supply, supplyOther);
        uint256 newSupply = supply + usdtAmount.divWad(spotPrice);

        // 设置二分法的上下界（基于当前价格和新价格）
        // 买入情况，价格会上升
        uint256 upperBound = newSupply;
        uint256 lowerBound = supply;

        // 设置精度要求 1/1000
        int256 precision = (usdtAmount / APPROXIMATION_PRECISION).toInt256();

        // 添加循环次数限制
        uint iterations = 0;

        // 进行二分查找
        while (iterations < MAX_ITERATIONS) {
            uint256 mid = (lowerBound + upperBound) / 2;

            // 计算mid数量token的平均价格
            uint256 price = getExecutionPrice(supply, supplyOther, mid.toInt256());

            // 计算总价值（USDT，6位小数）
            uint256 totalValue = price.mulWad(mid - supply);
            int256 usdtDiff = usdtAmount.toInt256() - totalValue.toInt256();

            if (totalValue < usdtAmount) {
                lowerBound = mid;
            } else if (totalValue > usdtAmount) {
                upperBound = mid;
            } else {
                // 找到精确匹配
                return (mid - supply, price);
            }

            if (usdtDiff > 0 && usdtDiff <= precision) {
                return (mid - supply, price);
            }

            // 增加迭代计数
            iterations++;
        }

        revert ApproximationFailed();
    }
}
