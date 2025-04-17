// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console2} from "../../forge-std/src/Test.sol";
import {Price} from "../src/Price.sol";

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
        uint256 expectedPrice;
        bool expectedRevert;
    }

    // 定义为状态变量
    TestCase[] internal testCases;
    ExecutionPriceTestCase[] internal executionPriceTestCases;

    function setUp() public {}

    function runTestCases(TestCase[] storage cases) internal view {
        for (uint256 i = 0; i < cases.length; i++) {
            uint256 price = Price.getSpotPrice(cases[i].supply, cases[i].supplyOther);    
            assertEq(price, cases[i].expectedPrice);
        }
    }
    
    function runExecutionPriceTestCases(ExecutionPriceTestCase[] storage cases) internal {
        for (uint256 i = 0; i < cases.length; i++) {
            if (cases[i].expectedRevert) {
                vm.expectRevert();
                Price.getExecutionPrice(cases[i].supply, cases[i].supplyOther, cases[i].deltaSupply);
            } else {
                uint256 executionPrice = Price.getExecutionPrice(cases[i].supply, cases[i].supplyOther, cases[i].deltaSupply);
                
                // 只有当测试将要失败时记录日志
                if (executionPrice != cases[i].expectedPrice) {
                    console2.log("Failed Test Case #", i);
                    console2.log("  supply:", cases[i].supply);
                    console2.log("  supplyOther:", cases[i].supplyOther);
                    console2.log("  deltaSupply:", cases[i].deltaSupply);
                    console2.log("  expectedPrice:", cases[i].expectedPrice);
                    console2.log("  Actual price:", executionPrice);
                    console2.log("-----------------------");
                }
                
                assertEq(executionPrice, cases[i].expectedPrice);
            }
        }
    }

    function test_GetSpotPrice() public {
        delete testCases; // 清空数组
        testCases.push(TestCase(0, 0, 100000));
        testCases.push(TestCase(1 ether, 0, 105999));
        testCases.push(TestCase(0 ether, 1 ether, 100000));
        testCases.push(TestCase(1 ether, 1 ether, 105998));

        runTestCases(testCases);
    }

    function test_GetExecutionPrice() public {
        delete executionPriceTestCases; // 清空数组

        // 初始情况
        executionPriceTestCases.push(ExecutionPriceTestCase(0, 0, 0 ether, 0, true));
        executionPriceTestCases.push(ExecutionPriceTestCase(0, 0, -1 ether, 0, true));
        executionPriceTestCases.push(ExecutionPriceTestCase(0, 0, 1 ether, 103833, false));
        executionPriceTestCases.push(ExecutionPriceTestCase(0, 0, 0.01 ether, 100338, false));
        executionPriceTestCases.push(ExecutionPriceTestCase(0, 0, 10000 ether, 1193543, false));
        executionPriceTestCases.push(ExecutionPriceTestCase(0, 0, 10000000 ether, 11640004, false));

        // 一方supply为0的情况
        executionPriceTestCases.push(ExecutionPriceTestCase(1 ether, 0, 1 ether, 107592, false));
        executionPriceTestCases.push(ExecutionPriceTestCase(1 ether, 0, -1 ether, 103833, false));
        executionPriceTestCases.push(ExecutionPriceTestCase(1000 ether, 0, 100 ether, 774101, false));
        executionPriceTestCases.push(ExecutionPriceTestCase(0, 1 ether, 1 ether, 103832, false));
        executionPriceTestCases.push(ExecutionPriceTestCase(0, 1 ether, -1 ether, 0, true));
        executionPriceTestCases.push(ExecutionPriceTestCase(0, 1000 ether, 100 ether, 157530, false));

        // 买方
        executionPriceTestCases.push(ExecutionPriceTestCase(1 ether, 1 ether, 1 ether, 107590, false));
        executionPriceTestCases.push(ExecutionPriceTestCase(10 ether, 10 ether, 1 ether, 126489, false));
        executionPriceTestCases.push(ExecutionPriceTestCase(10 ether, 10 ether, 100 ether, 192789, false));
        executionPriceTestCases.push(ExecutionPriceTestCase(10000000 ether, 100000 ether, 10000 ether, 16905346, false));
        executionPriceTestCases.push(ExecutionPriceTestCase(100000 ether, 10000000 ether, 10000 ether, 1730421, false));

        // 卖方
        executionPriceTestCases.push(ExecutionPriceTestCase(1 ether, 1 ether, -1 ether, 103832, false));
        executionPriceTestCases.push(ExecutionPriceTestCase(10 ether, 10 ether, -1 ether, 124727, false));
        executionPriceTestCases.push(ExecutionPriceTestCase(10 ether, 10 ether, -100 ether, 192789, true));
        executionPriceTestCases.push(ExecutionPriceTestCase(10000000 ether, 100000 ether, -10000 ether, 16897430, false));
        executionPriceTestCases.push(ExecutionPriceTestCase(100000 ether, 10000000 ether, -10000 ether, 1650335, false));

        // Run
        runExecutionPriceTestCases(executionPriceTestCases);
    }

    function test_SingleGetExecutionPrice() public {
        Price.getExecutionPrice(10000 ether, 10000 ether, 10 ether);
    }
    function test_SingleGetPrice() public {
        Price.getExecutionPrice(10000 ether, 10000 ether, 10 ether);
    }

    function test_SingleApproximateExecutionPrice() public {
        // 测试用例1: 初始状态，小额购买
        uint256 usdtProvided = 100 * 1e6;
        (uint256 supplyDelta, uint256 avgPrice) = Price.approximateExecutionPrice(10000 ether, 10000 ether, usdtProvided);
    //     uint256 actualUsdtValue = avgPrice * supplyDelta / 1e18;
    //     console2.log("supply change:", supplyDelta);
    //     console2.log("avgPrice:", avgPrice);
    //     console2.log("actual usdt value:", actualUsdtValue);
    //     assertLe(actualUsdtValue, usdtProvided);
    //     assertApproxEqAbs(actualUsdtValue, usdtProvided, usdtProvided / 1e3);
    }

    function test_MultipleApproximateExecutionPrice() public {
        // 设置随机种子
        uint256 seed = 12345;
        
        // 第一组测试：大范围
        for (uint256 i = 0; i < 100; i++) {
            // 生成随机供应量 (0 - 10亿 ether)
            uint256 supply = uint256(keccak256(abi.encodePacked(seed, i, "supply"))) % (10e9 ether);
            uint256 supplyOther = uint256(keccak256(abi.encodePacked(seed, i, "supplyOther"))) % (10e9 ether);
            
            // 生成随机USDT金额 (0 - 1000万)
            uint256 usdtAmount = uint256(keccak256(abi.encodePacked(seed, i, "usdt"))) % (10e6 * 1e6);
            
            (uint256 supplyDelta, uint256 avgPrice) = Price.approximateExecutionPrice(
                supply, supplyOther, usdtAmount
            );
            
            uint256 actualUsdtValue = avgPrice * supplyDelta / 1e18;
            assertLe(actualUsdtValue, usdtAmount);
            assertApproxEqAbs(actualUsdtValue, usdtAmount, usdtAmount / Price.APPROXIMATION_PRECISION);
        }
        
        // 第二组测试：小范围
        for (uint256 i = 0; i < 100; i++) {
            // 生成随机供应量 (0 - 100 ether)
            uint256 supply = uint256(keccak256(abi.encodePacked(seed, i + 100, "supply"))) % (100 ether);
            uint256 supplyOther = uint256(keccak256(abi.encodePacked(seed, i + 100, "supplyOther"))) % (100 ether);
            
            // 生成随机USDT金额 (0 - 10)
            uint256 usdtAmount = uint256(keccak256(abi.encodePacked(seed, i + 100, "usdt"))) % (10 * 1e6);
            
            (uint256 supplyDelta, uint256 avgPrice) = Price.approximateExecutionPrice(
                supply, supplyOther, usdtAmount
            );
            
            uint256 actualUsdtValue = avgPrice * supplyDelta / 1e18;
            assertLe(actualUsdtValue, usdtAmount);
            assertApproxEqAbs(actualUsdtValue, usdtAmount, usdtAmount / Price.APPROXIMATION_PRECISION);
        }
    }
} 