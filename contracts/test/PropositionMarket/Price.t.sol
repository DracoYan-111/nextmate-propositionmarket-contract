// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {Price} from "price/src/Price.sol";

contract PriceTest is Test {
    struct TestCase {
        uint256 supply;
        uint256 supplyOther;
        uint256 expectedPrice;
    }

    struct ExecutionPriceTestCase {
        uint256 supply;
        uint256 supplyOther;
        int256 deltaSupply;
        bool expectedRevert;
    }

    // 定义为状态变量
    TestCase[] internal _testCases;
    ExecutionPriceTestCase[] internal _executionPriceTestCases;

    function setUp() public {}

    function _runTestCases(TestCase[] storage cases) internal view {
        for (uint256 i = 0; i < cases.length; i++) {
            uint256 price = Price.getSpotPrice(cases[i].supply, cases[i].supplyOther);
            assertEq(price, cases[i].expectedPrice);
        }
    }

    // 模拟执行价格计算，将供应量变动分成1000部分并计算平均价格
    function _simulateExecutionPrice(
        uint256 supply,
        uint256 supplyOther,
        int256 deltaSupply
    ) internal pure returns (uint256) {
        // 如果deltaSupply为0，返回当前现货价格
        if (deltaSupply == 0) {
            return Price.getSpotPrice(supply, supplyOther);
        }

        // 只有当deltaSupply是负数且绝对值大于supply时才会回滚
        // deltaSupply + supply < 0 会回滚
        if (deltaSupply < 0 && uint256(-deltaSupply) > supply) {
            return 0; // 返回0表示这种情况会导致回滚
        }

        // 将变动分成1000部分
        uint256 parts = 1000;
        int256 stepDelta = deltaSupply / int256(parts);

        // 确保至少变动1 wei
        if (stepDelta == 0) {
            stepDelta = deltaSupply > 0 ? int256(1) : int256(-1);
            parts = uint256(deltaSupply > 0 ? deltaSupply : -deltaSupply);
        }

        uint256 totalPrice = 0;
        uint256 currentSupply = supply;
        uint256 validSteps = 0;

        // 逐步调整供应量并累计价格
        for (uint256 i = 0; i < parts; i++) {
            // 计算当前现货价格
            uint256 spotPrice = Price.getSpotPrice(currentSupply, supplyOther);
            totalPrice += spotPrice;
            validSteps++;

            // 调整当前供应量
            if (stepDelta > 0) {
                currentSupply += uint256(stepDelta);
            } else {
                // 确保不会因为减法而下溢
                if (currentSupply < uint256(-stepDelta)) {
                    break; // 无法继续减少，防止下溢
                }
                currentSupply -= uint256(-stepDelta);
            }
        }

        // 返回平均价格，避免除以零
        return validSteps > 0 ? totalPrice / validSteps : 0;
    }

    function _runExecutionPriceTestCases(ExecutionPriceTestCase[] storage cases) internal view {
        for (uint256 i = 0; i < cases.length; i++) {
            if (cases[i].expectedRevert) {
                // 使用try-catch确认是否会revert
                try this.callExecutionPrice(cases[i].supply, cases[i].supplyOther, cases[i].deltaSupply) returns (
                    uint256
                ) {
                    // 如果没有revert，测试失败

                    assertTrue(false, "Expected function to revert but it didn't");
                } catch {
                    // 预期的revert发生了，测试通过
                }
            } else {
                uint256 executionPrice = Price.getExecutionPrice(
                    cases[i].supply,
                    cases[i].supplyOther,
                    cases[i].deltaSupply
                );

                // 计算模拟的执行价格
                uint256 simulatedPrice = _simulateExecutionPrice(
                    cases[i].supply,
                    cases[i].supplyOther,
                    cases[i].deltaSupply
                );

                // 计算实际价格与模拟价格的差异百分比
                uint256 priceDiff;
                if (simulatedPrice == 0) {
                    // 避免除以零错误
                    priceDiff = executionPrice > 0 ? 10000 : 0; // 设为100%差异如果一个为0一个不为0
                } else if (executionPrice > simulatedPrice) {
                    priceDiff = ((executionPrice - simulatedPrice) * 10000) / simulatedPrice; // 差异*10000表示百分比的100倍
                } else {
                    priceDiff = ((simulatedPrice - executionPrice) * 10000) / simulatedPrice;
                }

                // 检查差异是否小于0.1%（即10个基点）
                bool diffAcceptable = priceDiff < 10; // 0.1% = 10个基点

                // 只有当差异过大时记录日志
                if (!diffAcceptable) {}

                // 验证与模拟价格的接近程度
                assertTrue(diffAcceptable, "Execution price differs too much from simulation");
            }
        }
    }

    // 用于try-catch测试
    function callExecutionPrice(
        uint256 supply,
        uint256 supplyOther,
        int256 deltaSupply
    ) external pure returns (uint256) {
        return Price.getExecutionPrice(supply, supplyOther, deltaSupply);
    }

    function test_GetSpotPrice() public {
        delete _testCases; // 清空数组
        _testCases.push(TestCase(0, 0, 100000000000000000));
        _testCases.push(TestCase(1 ether, 0, 105999000999000999));
        _testCases.push(TestCase(0 ether, 1 ether, 100000000000000000));
        _testCases.push(TestCase(1 ether, 1 ether, 105998003992015968));

        _runTestCases(_testCases);
    }

    function test_GetExecutionPrice() public {
        delete _executionPriceTestCases; // 清空数组

        // 初始情况
        _executionPriceTestCases.push(ExecutionPriceTestCase(0, 0, 0 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(0, 0, -1 ether, true));
        _executionPriceTestCases.push(ExecutionPriceTestCase(0, 0, 1 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(0, 0, 0.01 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(0, 0, 10000 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(0, 0, 10000000 ether, false));

        // 一方supply为0的情况
        _executionPriceTestCases.push(ExecutionPriceTestCase(1 ether, 0, 1 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(1 ether, 0, -1 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(1000 ether, 0, 100 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(0, 1 ether, 1 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(0, 1 ether, -1 ether, true));
        _executionPriceTestCases.push(ExecutionPriceTestCase(0, 1000 ether, 100 ether, false));

        // 买方
        _executionPriceTestCases.push(ExecutionPriceTestCase(1 ether, 1 ether, 1 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(10 ether, 10 ether, 1 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(10 ether, 10 ether, 100 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(10000000 ether, 100000 ether, 10000 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(100000 ether, 10000000 ether, 10000 ether, false));

        // 卖方
        _executionPriceTestCases.push(ExecutionPriceTestCase(1 ether, 1 ether, -1 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(10 ether, 10 ether, -1 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(10 ether, 10 ether, -100 ether, true));
        _executionPriceTestCases.push(ExecutionPriceTestCase(10000000 ether, 100000 ether, -10000 ether, false));
        _executionPriceTestCases.push(ExecutionPriceTestCase(100000 ether, 10000000 ether, -10000 ether, false));

        // 添加随机测试
        // 设置随机种子
        uint256 seed = 12345;

        // 第一组：大范围随机测试，buy情况
        for (uint256 i = 0; i < 100; i++) {
            // 生成随机供应量 (0 - 10亿 ether)
            uint256 supply = uint256(keccak256(abi.encodePacked(seed, i, "supply"))) % (10e9 ether);
            uint256 supplyOther = uint256(keccak256(abi.encodePacked(seed, i, "supplyOther"))) % (10e9 ether);

            // 随机买入量，保证是正数
            int256 deltaSupply = int256(uint256(keccak256(abi.encodePacked(seed, i, "delta"))) % (supply * 10));

            _executionPriceTestCases.push(ExecutionPriceTestCase(supply, supplyOther, deltaSupply, false));
        }

        // 第二组：随机测试，sell情况
        for (uint256 i = 0; i < 100; i++) {
            // 生成随机供应量
            uint256 supply = uint256(keccak256(abi.encodePacked(seed, i + 100, "supply"))) % (10e9 ether);
            uint256 supplyOther = uint256(keccak256(abi.encodePacked(seed, i + 100, "supplyOther"))) % (10e9 ether);

            // 随机卖出量，保证是负数且绝对值小于supply（确保合法）
            uint256 sellAmount = uint256(keccak256(abi.encodePacked(seed, i + 100, "delta"))) % (supply - 1);
            int256 deltaSupply = -int256(sellAmount);

            _executionPriceTestCases.push(ExecutionPriceTestCase(supply, supplyOther, deltaSupply, false));
        }

        // 第三组：边界测试，卖出接近全部供应量
        for (uint256 i = 0; i < 100; i++) {
            uint256 supply = 1000 ether + i;
            uint256 supplyOther = uint256(keccak256(abi.encodePacked(seed, i + 200, "supplyOther"))) % (10e6 ether);

            // 卖出几乎全部供应量，但保留一些
            int256 deltaSupply = -int256(supply - 1);

            _executionPriceTestCases.push(ExecutionPriceTestCase(supply, supplyOther, deltaSupply, false));
        }

        // 运行随机测试用例
        _runExecutionPriceTestCases(_executionPriceTestCases);
    }

    function test_SingleGetExecutionPrice() public pure {
        Price.getExecutionPrice(10000 ether, 10000 ether, 10 ether);
    }

    function test_SingleGetPrice() public pure {
        Price.getExecutionPrice(10000 ether, 10000 ether, 10 ether);
    }

    function test_SingleApproximateExecutionPrice() public pure {
        // 测试用例1: 初始状态，小额购买
        uint256 usdtProvided = 100 * 1e6;
        // 不使用返回值，仅测试函数不会revert
        Price.approximateExecutionPrice(10000 ether, 10000 ether, usdtProvided);
    }

    function test_MultipleApproximateExecutionPrice() public pure {
        // 设置随机种子
        uint256 seed = 12345;

        // 第一组测试：大范围
        for (uint256 i = 0; i < 100; i++) {
            // 生成随机供应量 (0 - 10亿 ether)
            uint256 supply = uint256(keccak256(abi.encodePacked(seed, i, "supply"))) % (10e9 ether);
            uint256 supplyOther = uint256(keccak256(abi.encodePacked(seed, i, "supplyOther"))) % (10e9 ether);

            // 生成随机USDT金额 (0 - 1000万)
            uint256 usdtAmount = uint256(keccak256(abi.encodePacked(seed, i, "usdt"))) % (10e6 * 1e6);

            (uint256 supplyDelta, uint256 avgPrice) = Price.approximateExecutionPrice(supply, supplyOther, usdtAmount);

            uint256 actualUsdtValue = (avgPrice * supplyDelta) / 1e18;
            assertLe(actualUsdtValue, usdtAmount);
            assertEq(Price.getExecutionPrice(supply, supplyOther, int256(supplyDelta)), avgPrice);

            assertApproxEqAbs(actualUsdtValue, usdtAmount, usdtAmount / Price.DEFAULT_APPROXIMATION_PRECISION);
        }

        // 第二组测试：小范围
        for (uint256 i = 0; i < 100; i++) {
            // 生成随机供应量 (0 - 100 ether)
            uint256 supply = uint256(keccak256(abi.encodePacked(seed, i + 100, "supply"))) % (100 ether);
            uint256 supplyOther = uint256(keccak256(abi.encodePacked(seed, i + 100, "supplyOther"))) % (100 ether);

            // 生成随机USDT金额 (0 - 10)
            uint256 usdtAmount = uint256(keccak256(abi.encodePacked(seed, i + 100, "usdt"))) % (10 * 1e6);

            (uint256 supplyDelta, uint256 avgPrice) = Price.approximateExecutionPrice(supply, supplyOther, usdtAmount);

            uint256 actualUsdtValue = (avgPrice * supplyDelta) / 1e18;
            assertLe(actualUsdtValue, usdtAmount);
            assertEq(Price.getExecutionPrice(supply, supplyOther, int256(supplyDelta)), avgPrice);
            assertApproxEqAbs(actualUsdtValue, usdtAmount, usdtAmount / Price.DEFAULT_APPROXIMATION_PRECISION);
        }
    }
}
