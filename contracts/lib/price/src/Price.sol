// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";
import {SafeCastLib} from "solady/src/utils/SafeCastLib.sol";
import {console2} from "forge-std/console2.sol";

/**
 * @title Price Library
 * @notice Bonding‑curve pricing 
 *
 * ### 公式摘要
 * * **A** = (s₁+v)^α + (s₂+v)^α
 * * **Spot Price**
 *   * y₁ = (s₁ + v)^{α−1} · A^{1/α − 1}  +  k·√s₁
 *   * y₂ = (s₂ + v)^{α−1} · A^{1/α − 1}  +  k·√s₂
 * * **Potential**   F(s₁,s₂) = A^{1/α} + (2/3)·k·(s₁^{1.5}+s₂^{1.5})
 * * **执行均价**  Pₑₓₑc = (F(new) − F(old)) / Δs
 *
 * 所有数值采用 18‑decimals **WAD**。
 */
library Price {
    using FixedPointMathLib for *;
    using SafeCastLib for uint256;
    using SafeCastLib for int256;

    /*────────────────────── CONSTANTS ──────────────────────*/

    uint256 public constant ALPHA = 1.25 ether;            // α = 1.25 (18‑dec)
    uint256 public constant ONE_OVER_ALPHA = 0.8 ether;     // 1 / α
    uint256  public constant ALPHA_MINUS_ONE = 0.25 ether;   // α − 1
    int256  public constant ONE_OVER_ALPHA_MINUS_ONE = -0.2 ether; // 1/α − 1

    uint256 public constant V     = 10000 ether;            // v  = 10000
    uint256 public constant K     = 0.005 ether;           // k  = 0.005

    /// @notice Binary‑search 控制参数
    uint256 public constant DEFAULT_MAX_ITERATIONS        = 30;
    uint256 public constant DEFAULT_APPROXIMATION_PRECISION = 1e3;

    /*────────────────────── CUSTOM ERRORS ───────────────────*/

    error NegativePrice(int256 price);
    error InsufficientSupply(int256 supply);
    error ApproximationFailed(uint256 supply, uint256 supplyOther, uint256 usdtAmount);

    /*──────────────────── INTERNAL HELPERS ─────────────────*/

    /// @dev 势能函数 F(s₁,s₂)
    function _potential(uint256 s1, uint256 s2) internal pure returns (uint256) {
        uint256 s1p = s1 + V;
        uint256 s2p = s2 + V;

        // (s+v)^α
        uint256 s1Alpha = FixedPointMathLib.powWad(s1p.toInt256(), ALPHA.toInt256()).toUint256();
        uint256 s2Alpha = FixedPointMathLib.powWad(s2p.toInt256(), ALPHA.toInt256()).toUint256();
        uint256 A = s1Alpha + s2Alpha;

        // A^{1/α}
        uint256 first = FixedPointMathLib.powWad(A.toInt256(), ONE_OVER_ALPHA.toInt256()).toUint256();

        // (2/3)·k·(s^{1.5})
        uint256 s1_15 = s1.mulWad(s1.sqrtWad());
        uint256 s2_15 = s2.mulWad(s2.sqrtWad());
        uint256 second = ((2 * K).mulWad(s1_15 + s2_15)) / 3;
        return first + second;
    }

    /*────────────────────── PUBLIC API ─────────────────────*/

    /// @notice 计算 Token‑1 的现货价
    function getSpotPrice(uint256 supply, uint256 supplyOther) public pure returns (uint256) {
        uint256 s1p = supply + V;
        uint256 s2p = supplyOther + V;

        // (s+v)^{α−1}
        uint256 s1Factor = FixedPointMathLib.powWad(s1p.toInt256(), ALPHA_MINUS_ONE.toInt256()).toUint256();

        // A = (s₁+v)^α + (s₂+v)^α
        uint256 s1Alpha = FixedPointMathLib.powWad(s1p.toInt256(), ALPHA.toInt256()).toUint256();
        uint256 s2Alpha = FixedPointMathLib.powWad(s2p.toInt256(), ALPHA.toInt256()).toUint256();
        uint256 A = s1Alpha + s2Alpha;

        // A^{1/α − 1}
        uint256 common = FixedPointMathLib.powWad(A.toInt256(), ONE_OVER_ALPHA_MINUS_ONE).toUint256();

        uint256 firstTerm = s1Factor.mulWad(common);
        uint256 sqrtTerm  = K.mulWad(supply.sqrtWad());

        return firstTerm + sqrtTerm;
    }

    /// @notice Δs 的平均执行价
    function getExecutionPrice(uint256 supply, uint256 supplyOther, int256 deltaSupply) public pure returns (uint256) {
        if (deltaSupply == 0) return getSpotPrice(supply, supplyOther);
        int256 dF = getDeltaUSDT(supply, supplyOther, deltaSupply);
        int256 avg = dF.sDivWad(deltaSupply);
        if (avg < 0) revert NegativePrice(avg);
        return avg.toUint256();
    }

    function getDeltaUSDT(uint256 supply, uint256 supplyOther, int256 deltaSupply) public pure returns (int256) {
        if (supply.toInt256() + deltaSupply < 0) revert InsufficientSupply(supply.toInt256() + deltaSupply);

        uint256 newSupply = deltaSupply > 0 ? supply + deltaSupply.toUint256() : supply - (-deltaSupply).toUint256();

        uint256 F0 = _potential(supply, supplyOther);
        uint256 F1 = _potential(newSupply, supplyOther);

        int256 dF = F1.toInt256() - F0.toInt256();
        return dF;
    }

    /*──────── Binary‑search：给定 USDT 计算可购数量 ────────*/

    function approximateExecutionPrice(
        uint256 supply,
        uint256 supplyOther,
        uint256 usdtAmount,
        uint256 approxPrecision,
        uint256 maxIteration
    ) public pure returns (uint256 tokenAmount, uint256 avgPrice) {
        uint256 upperBound = supply + usdtAmount.divWad(getSpotPrice(supply, supplyOther));
        uint256 lowerBound = supply;

        int256 precision = (usdtAmount / approxPrecision).toInt256();
        uint256 iterations;
        while (iterations < maxIteration) {
            uint256 mid = (lowerBound + upperBound) / 2;
            uint256 delta = mid - supply;

            uint256 price = getExecutionPrice(supply, supplyOther, delta.toInt256());
            uint256 totalValue = price.mulWad(delta);
            int256 diff = usdtAmount.toInt256() - totalValue.toInt256();

            if (diff > 0 && diff <= precision) return (delta, price);
            if (totalValue < usdtAmount) lowerBound = mid;
            else upperBound = mid;
            iterations++;
            if (iterations >= maxIteration) {
                console2.log("iterations", iterations);
                console2.log("lowerBound", lowerBound);
                console2.log("upperBound", upperBound);
                console2.log("price", price);
                console2.log("totalValue", totalValue);
            }
        }
        revert ApproximationFailed(supply, supplyOther, usdtAmount);
    }

    /// @notice overload，使用默认精度/迭代上限
    function approximateExecutionPrice(
        uint256 supply,
        uint256 supplyOther,
        uint256 usdtAmount
    ) public pure returns (uint256 tokenAmount, uint256 avgPrice) {
        return
            approximateExecutionPrice(
                supply,
                supplyOther,
                usdtAmount,
                DEFAULT_APPROXIMATION_PRECISION,
                DEFAULT_MAX_ITERATIONS
            );
    }
}
