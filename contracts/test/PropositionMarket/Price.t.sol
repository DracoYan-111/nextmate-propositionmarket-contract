// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {Price} from "../../src/PropositionMarket/Price.sol";

contract PriceTest is Test {
    struct TestCase {
        uint256 supply;
        uint256 supplyOther;
        uint256 expectedPrice;
    }
    
    struct AveragePriceTestCase {
        uint256 supply;
        uint256 supplyOther;
        int256 deltaSupply;
        uint256 expectedPrice;
        bool expectedRevert;
    }

    // 定义为状态变量
    TestCase[] internal testCases;
    AveragePriceTestCase[] internal avgPriceTestCases;

    function setUp() public {}

    function runTestCases(TestCase[] storage cases) internal view {
        for (uint256 i = 0; i < cases.length; i++) {
            uint256 price = Price.getSpotPrice(cases[i].supply, cases[i].supplyOther);    
            assertEq(price, cases[i].expectedPrice);
        }
    }
    
    function runAveragePriceTestCases(AveragePriceTestCase[] storage cases) internal {
        for (uint256 i = 0; i < cases.length; i++) {
            if (cases[i].expectedRevert) {
                vm.expectRevert();
                Price.getAveragePrice(cases[i].supply, cases[i].supplyOther, cases[i].deltaSupply);
            } else {
                uint256 avgPrice = Price.getAveragePrice(cases[i].supply, cases[i].supplyOther, cases[i].deltaSupply);
                
                // 只有当测试将要失败时记录日志
                if (avgPrice != cases[i].expectedPrice) {
                    console2.log("Failed Test Case #", i);
                    console2.log("  supply:", cases[i].supply);
                    console2.log("  supplyOther:", cases[i].supplyOther);
                    console2.log("  deltaSupply:", cases[i].deltaSupply);
                    console2.log("  expectedPrice:", cases[i].expectedPrice);
                    console2.log("  Actual price:", avgPrice);
                    console2.log("-----------------------");
                }
                
                assertEq(avgPrice, cases[i].expectedPrice);
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

    function test_GetAveragePrice() public {
        delete avgPriceTestCases; // 清空数组

        // 初始情况
        avgPriceTestCases.push(AveragePriceTestCase(0, 0, -1 ether, 0, true));
        avgPriceTestCases.push(AveragePriceTestCase(0, 0, 1 ether, 103833, false));
        avgPriceTestCases.push(AveragePriceTestCase(0, 0, 0.01 ether, 100338, false));
        avgPriceTestCases.push(AveragePriceTestCase(0, 0, 10000 ether, 1193543, false));
        avgPriceTestCases.push(AveragePriceTestCase(0, 0, 10000000 ether, 11640004, false));

        // 一方supply为0的情况
        avgPriceTestCases.push(AveragePriceTestCase(1 ether, 0, 1 ether, 107592, false));
        avgPriceTestCases.push(AveragePriceTestCase(1 ether, 0, -1 ether, 103833, false));
        avgPriceTestCases.push(AveragePriceTestCase(1000 ether, 0, 100 ether, 774101, false));
        avgPriceTestCases.push(AveragePriceTestCase(0, 1 ether, 1 ether, 103832, false));
        avgPriceTestCases.push(AveragePriceTestCase(0, 1 ether, -1 ether, 0, true));
        avgPriceTestCases.push(AveragePriceTestCase(0, 1000 ether, 100 ether, 157530, false));

        // 买方
        avgPriceTestCases.push(AveragePriceTestCase(1 ether, 1 ether, 1 ether, 107590, false));
        avgPriceTestCases.push(AveragePriceTestCase(10 ether, 10 ether, 1 ether, 126489, false));
        avgPriceTestCases.push(AveragePriceTestCase(10 ether, 10 ether, 100 ether, 192789, false));
        avgPriceTestCases.push(AveragePriceTestCase(10000000 ether, 100000 ether, 10000 ether, 16905346, false));
        avgPriceTestCases.push(AveragePriceTestCase(100000 ether, 10000000 ether, 10000 ether, 1730421, false));

        // 卖方
        avgPriceTestCases.push(AveragePriceTestCase(1 ether, 1 ether, -1 ether, 103832, false));
        avgPriceTestCases.push(AveragePriceTestCase(10 ether, 10 ether, -1 ether, 124727, false));
        avgPriceTestCases.push(AveragePriceTestCase(10 ether, 10 ether, -100 ether, 192789, true));
        avgPriceTestCases.push(AveragePriceTestCase(10000000 ether, 100000 ether, -10000 ether, 16897430, false));
        avgPriceTestCases.push(AveragePriceTestCase(100000 ether, 10000000 ether, -10000 ether, 1650335, false));

        // Run
        runAveragePriceTestCases(avgPriceTestCases);
    }
} 