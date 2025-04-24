// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {SSTORE2} from "solady/src/utils/SSTORE2.sol";

import {PropositionMarketFactory, FactorySettings, TokenSettings, MarketSettings} from "../../src/PropositionMarket/PropositionMarketFactory.sol";
import {PropositionMarketToken, ERC20, Ownable} from "../../src/PropositionMarket/PropositionMarketToken.sol";
import {IPropositionMarketToken, IPropositionMarketPool, PropositionMarketPool} from "../../src/PropositionMarket/PropositionMarketPool.sol";
import {TestToken} from "../../src/PropositionMarket/utils/TestToken.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Test, console} from "forge-std/Test.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

contract PropositionMarketPoolTest is Test {
    PropositionMarketFactory public propositionMarketFactory;
    TokenSettings[] public nameAndSymbolList;
    TestToken public testTokenAddress;

    using FixedPointMathLib for *;

    address public initialOwner;
    uint256 public constant INITIALOWNERKEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    /**
     * @dev Sets up the test.
     */
    function setUp() external {
        initialOwner = vm.addr(INITIALOWNERKEY);

        address propositionMarketFactoryAddress = address(new PropositionMarketFactory());

        address tokenAddress = address(new PropositionMarketToken());
        address propositionMarketPool = address(new PropositionMarketPool());
        testTokenAddress = new TestToken(initialOwner);

        bytes memory data = abi.encodeCall(
            PropositionMarketFactory.initialize,
            (
                initialOwner,
                propositionMarketPool,
                tokenAddress,
                FactorySettings({feeRecipient: initialOwner, platformFee: 0.01 ether})
            )
        );
        address proxy = address(new ERC1967Proxy(propositionMarketFactoryAddress, data));

        propositionMarketFactory = PropositionMarketFactory(proxy);

        nameAndSymbolList = new TokenSettings[](2);

        nameAndSymbolList[0].owner = address(propositionMarketFactory);
        nameAndSymbolList[0].name = "Test Token One";
        nameAndSymbolList[0].symbol = "TTO";

        nameAndSymbolList[1].owner = address(propositionMarketFactory);
        nameAndSymbolList[1].name = "Test Token Two";
        nameAndSymbolList[1].symbol = "TTT";
    }

    function test_optionListlength() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner
        );

        assertEq(PropositionMarketPool(pool).getOptionListLength(), nameAndSymbolList.length);
    }

    function test_optionList() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner
        );

        address[] memory propositionTokenAddressList = propositionMarketFactory.predictDeterministicAddress(
            nameAndSymbolList
        );

        address[] memory tokenAddressList = PropositionMarketPool(pool).getOptionList();

        assertEq(propositionTokenAddressList.length, tokenAddressList.length);

        for (uint256 i; i < tokenAddressList.length; i++) {
            assertEq(propositionTokenAddressList[i], tokenAddressList[i]);
        }
    }

    function test_getFactoryAddress() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner
        );

        assertEq(PropositionMarketPool(pool).getFactoryAddress(), address(propositionMarketFactory));
    }

    function test_getManagerAddress() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner
        );

        assertEq(PropositionMarketPool(pool).getManagerAddress(), initialOwner);
    }

    function test_getPoolTitle() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner
        );

        assertEq(PropositionMarketPool(pool).getPoolTitle(), "testtesttesttest");
    }

    function test_getPayTokenAddress() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner
        );

        assertEq(address(PropositionMarketPool(pool).getPayTokenAddress()), address(testTokenAddress));
    }

    function test_factorySettings() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner
        );

        assertEq(PropositionMarketPool(pool).getFeeRecipient(), address(initialOwner));
        assertEq(PropositionMarketPool(pool).getPlatformFee(), 0.01 ether);
    }

    function test_receivePlatformFee() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner
        );

        vm.expectRevert(abi.encodeWithSelector(IPropositionMarketPool.InsufficientBalance.selector));
        PropositionMarketPool(pool).receivePlatformFee(initialOwner);

        vm.startPrank(
            address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8),
            address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IPropositionMarketPool.OwnableUnauthorizedAccount.selector,
                address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
            )
        );
        PropositionMarketPool(pool).receivePlatformFee(initialOwner);
    }

    function test_pausedPool() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner
        );

        vm.startPrank(
            address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8),
            address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IPropositionMarketPool.OwnableUnauthorizedAccount.selector,
                address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
            )
        );
        PropositionMarketPool(pool).pausedPool();

        vm.startPrank(initialOwner, initialOwner);

        PropositionMarketPool(pool).pausedPool();

        vm.expectRevert(abi.encodeWithSelector(IPropositionMarketPool.EnforcedPause.selector));
        PropositionMarketPool(pool).pausedPool();
    }

    function test_getPoolVersion() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner
        );

        assertEq(PropositionMarketPool(pool).getPoolVersion(), propositionMarketFactory.getPoolVersion());
    }

    function test_PoolRole() public {
        vm.startPrank(initialOwner, initialOwner);

        PropositionMarketPool pool = PropositionMarketPool(
            propositionMarketFactory.createContracts(
                nameAndSymbolList,
                "testtesttesttest",
                address(testTokenAddress),
                initialOwner
            )
        );

        assertEq(propositionMarketFactory.hasRole(propositionMarketFactory.POOL_ROLE(), address(pool)), true);
    }

    /**
     * @dev Tests the single-sided buy function.
     */
    function test_buy() public {
        vm.startPrank(initialOwner, initialOwner);

        PropositionMarketPool pool = PropositionMarketPool(
            propositionMarketFactory.createContracts(
                nameAndSymbolList,
                "testtesttesttest",
                address(testTokenAddress),
                initialOwner
            )
        );

        address[] memory tokenAddressList = pool.getOptionList();

        // Mint and approve USDT
        testTokenAddress.mint(initialOwner, 100 ether);
        testTokenAddress.approve(address(pool), 100 ether);

        uint256 usdtBalanceBefore = testTokenAddress.balanceOf(initialOwner);
        // uint256 tokenBalanceBefore = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);

        // 打印初始余额

        // Test basic buy for just one token (single-sided)
        uint256 maxUsdtProvided = 2 ether; // Max USDT to spend

        uint256 estimateServiceFee = maxUsdtProvided.mulWad(pool.getPlatformFee());
        uint256 usdtForBuyingToken = maxUsdtProvided.rawSub(estimateServiceFee);

        // 使用approximateExecutionPrice计算可以购买的token数量和平均价格
        (uint256 tokenAmount, ) = pool.getApproximatePrice(
            tokenAddressList[0],
            usdtForBuyingToken,
            1e9, // 1/1000000000 误差
            50 // 最多50次迭代
        );

        // uint256 tokensReceived =
        pool.buy(
            IPropositionMarketToken(tokenAddressList[0]),
            tokenAmount,
            maxUsdtProvided,
            uint256(0),
            block.timestamp + 3600
        );

        // Check token balance
        uint256 tokenBalance = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);

        //assertEq(tokenBalance, tokensReceived, "Token balance should match tokens received");

        // check usdt
        uint256 serviceFee = pool.totalPlatformFee();

        // uint256 usdtReceviedForPool = pool.optionTvl(tokenAddressList[0]);
        uint256 usdtBalance = testTokenAddress.balanceOf(initialOwner);
        uint256 usdtReduced = usdtBalanceBefore - usdtBalance;

        // assertEq(usdtReduced, usdtReceviedForPool + serviceFee, "USDT balance should match");
    }

    /**
     * @dev Tests the single-sided sell function.
     */
    function test_Sell() public {
        vm.startPrank(initialOwner, initialOwner);

        PropositionMarketPool pool = PropositionMarketPool(
            propositionMarketFactory.createContracts(
                nameAndSymbolList,
                "testtesttesttest",
                address(testTokenAddress),
                initialOwner
            )
        );

        address[] memory tokenAddressList = pool.getOptionList();

        // Mint and approve USDT
        testTokenAddress.mint(initialOwner, 100 ether);
        testTokenAddress.approve(address(pool), 100 ether);

        // First buy some tokens to sell later
        uint256 buyTokenAmount = 5 ether;

        uint256 tokensReceived = pool.buy(
            IPropositionMarketToken(tokenAddressList[0]),
            buyTokenAmount,
            100 ether,
            block.timestamp + 3600
        );

        // Record balances before selling
        uint256 usdtBalanceBefore = testTokenAddress.balanceOf(initialOwner);

        // uint256 tokenBalanceBefore = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);

        // uint256 platformFeeBefore = pool.totalPlatformFee();

        // uint256 optionTvlBefore = pool.optionTvl(tokenAddressList[0]);

        // Check pool's USDT balance before selling
        uint256 poolUsdtBalanceBefore = pool.getPayTokenAddress().balanceOf(address(pool));

        // Approve tokens to sell all
        uint256 tokensToSell = tokensReceived;

        IPropositionMarketToken(tokenAddressList[0]).approve(address(pool), tokensToSell);

        // Get expected sell price
        // uint256 expectedPrice = pool.getExecutionPrice(tokenAddressList[0], -int256(tokensToSell));

        // uint256 usdtReceived =
        pool.sell(
            IPropositionMarketToken(tokenAddressList[0]),
            tokensToSell,
            0, // No slippage protection
            block.timestamp + 3600
        );

        // Check token balance
        uint256 tokenBalance = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);

        assertEq(tokenBalance, tokensReceived - tokensToSell, "Token balance should be reduced by sold amount");

        // Check TVL change
        // uint256 optionTvlAfter = pool.optionTvl(tokenAddressList[0]);

        // uint256 tvlDiff = optionTvlBefore - optionTvlAfter;
        // assertEq(usdtReceived, tvlDiff, "USDT received should equal TVL reduction");

        // Check pool's USDT balance after selling
        uint256 poolUsdtBalanceAfter = pool.getPayTokenAddress().balanceOf(address(pool));

        uint256 poolUsdtDiff = poolUsdtBalanceBefore - poolUsdtBalanceAfter;

        // assertEq(poolUsdtDiff, usdtReceived, "Pool USDT balance reduction should equal USDT received");

        // Check USDT balance
        uint256 usdtBalanceAfter = testTokenAddress.balanceOf(initialOwner);

        // assertEq(usdtBalanceAfter, usdtBalanceBefore + usdtReceived, "USDT balance should increase by received amount");

        // Check platform fee and TVL
        // uint256 platformFeeAfter = pool.totalPlatformFee();
        // uint256 feeCollected = platformFeeAfter - platformFeeBefore;
    }

    /**
     * @dev Tests the buy function with slippage protection that fails.
     */
    function test_buyWithSlippageFailed() public {
        vm.startPrank(initialOwner, initialOwner);

        PropositionMarketPool pool = PropositionMarketPool(
            propositionMarketFactory.createContracts(
                nameAndSymbolList,
                "testtesttesttest",
                address(testTokenAddress),
                initialOwner
            )
        );

        address[] memory tokenAddressList = pool.getOptionList();

        // Mint and approve USDT
        testTokenAddress.mint(initialOwner, 100 ether);
        testTokenAddress.approve(address(pool), 100 ether);

        // 提供USDT金额
        uint256 usdtProvided = 2 ether;
        
        // 设置一个很高的最小代币接收量，确保会触发滑点保护
        uint256 minTokenReceived = 1000 ether;

        // 获取大致可以购买的代币数量
        (uint256 approxTokenAmount, ) = pool.getApproximatePrice(
            tokenAddressList[0],
            usdtProvided.rawSub(usdtProvided.mulWad(pool.getPlatformFee())), 
            1e9, 
            50
        );
        
        // 预期会因为滑点保护失败而回滚，并且验证错误参数
        vm.expectRevert(
            abi.encodeWithSelector(IPropositionMarketPool.SlippageFailed.selector, approxTokenAmount, minTokenReceived)
        );
        
        pool.buy(
            IPropositionMarketToken(tokenAddressList[0]),
            approxTokenAmount, // 使用计算出的预期代币数量
            usdtProvided,
            minTokenReceived, // 设置很高的最小接收量
            block.timestamp + 3600 // 过期时间
        );
    }
    
    /**
     * @dev Tests the buy function with slippage protection that succeeds despite price discrepancy.
     */
    function test_buyWithSlippageSucceeded() public {
        vm.startPrank(initialOwner, initialOwner);

        PropositionMarketPool pool = PropositionMarketPool(
            propositionMarketFactory.createContracts(
                nameAndSymbolList,
                "testtesttesttest",
                address(testTokenAddress),
                initialOwner
            )
        );

        address[] memory tokenAddressList = pool.getOptionList();

        // Mint and approve USDT
        testTokenAddress.mint(initialOwner, 100 ether);
        testTokenAddress.approve(address(pool), 100 ether);

        // 提供USDT金额
        uint256 usdtProvided = 2 ether;
        
        // 获取大致可以购买的代币数量
        (uint256 approxTokenAmount, ) = pool.getApproximatePrice(
            tokenAddressList[0],
            usdtProvided.rawSub(usdtProvided.mulWad(pool.getPlatformFee())), 
            1e9, 
            50
        );
        
        // 设置一个略低于预期数量的最小接收量，确保在可接受的滑点范围内
        uint256 minTokenReceived = approxTokenAmount.mulWad(0.95 ether); // 允许5%的滑点
        
        // 请求购买的金额故意设置为稍大于最小接收量，但小于预期值
        // 这样模拟了实际执行价格与预估价格有偏差的情况
        uint256 requestTokenAmount = minTokenReceived.rawAdd(1 ether); // 请求略高于最小接收量的值
        
        // 记录交易前的余额
        uint256 tokenBalanceBefore = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 usdtBalanceBefore = testTokenAddress.balanceOf(initialOwner);
        
        // 执行购买，预期应该成功（尽管获得的代币可能比请求的少，但会多于最小接收量）
        pool.buy(
            IPropositionMarketToken(tokenAddressList[0]),
            requestTokenAmount, // 请求购买金额大于最小接收量
            usdtProvided,
            minTokenReceived, // 最小接收量
            block.timestamp + 3600
        );
        
        // 验证交易成功并获得了代币
        uint256 tokenBalanceAfter = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 usdtBalanceAfter = testTokenAddress.balanceOf(initialOwner);
        uint256 tokenReceived = tokenBalanceAfter - tokenBalanceBefore;
        uint256 usdtSpent = usdtBalanceBefore - usdtBalanceAfter;
        
        // 输出实际值，帮助调试
        // console.log("Requested token amount:", requestTokenAmount);
        // console.log("Estimated token amount:", approxTokenAmount);
        // console.log("Minimum token required:", minTokenReceived);
        // console.log("Actually received tokens:", tokenReceived);
        // console.log("USDT spent:", usdtSpent);
        
        // 验证：
        // 1. 收到的代币数量大于等于最小接收量（滑点保护有效）
        assertGe(tokenReceived, minTokenReceived, "Received token amount should be >= minTokenReceived");
        
        // 2. 收到的代币可能小于请求的数量（因为有价格偏差）
        // 但一定小于等于预估可获得的最大数量
        assertLe(tokenReceived, requestTokenAmount, "Received token amount should be <= requestTokenAmount");
    }

    function test_sellWithSlippageFailed() public {
        vm.startPrank(initialOwner, initialOwner);

        PropositionMarketPool pool = PropositionMarketPool(
            propositionMarketFactory.createContracts(
                nameAndSymbolList,
                "testtesttesttest",
                address(testTokenAddress),
                initialOwner
            )
        );

        address[] memory tokenAddressList = pool.getOptionList();

        // Mint and approve USDT
        testTokenAddress.mint(initialOwner, 100 ether);
        testTokenAddress.approve(address(pool), 100 ether);

        // 先购买一些代币
        uint256 buyTokenAmount = 5 ether;
        uint256 tokensReceived = pool.buy(
            IPropositionMarketToken(tokenAddressList[0]),
            buyTokenAmount,
            100 ether,
            block.timestamp + 3600
        );

        // 准备卖出所有代币
        uint256 tokensToSell = tokensReceived;
        IPropositionMarketToken(tokenAddressList[0]).approve(address(pool), tokensToSell);
        
        // 计算预期可以获得的USDT金额
        uint256 tokenPrice = pool.getExecutionPrice(tokenAddressList[0], -int256(tokensToSell));
        uint256 expectedUsdtAmount = tokenPrice.mulWad(tokensToSell);
        uint256 platformFee = expectedUsdtAmount.mulWad(pool.getPlatformFee());
        uint256 expectedUsdtNetAmount = expectedUsdtAmount.rawSub(platformFee);
        
        // 设置一个高于预期金额的最小USDT接收量，确保会触发滑点保护
        uint256 minUsdtReceived = expectedUsdtNetAmount.rawAdd(1 ether);
        
        // 预期会因为滑点保护失败而回滚，并且验证错误参数
        vm.expectRevert(
            abi.encodeWithSelector(IPropositionMarketPool.SlippageFailed.selector, expectedUsdtNetAmount, minUsdtReceived)
        );
        
        pool.sell(
            IPropositionMarketToken(tokenAddressList[0]),
            tokensToSell, 
            minUsdtReceived, // 设置很高的最小接收量
            block.timestamp + 3600 // 过期时间
        );
    }
    
    /**
     * @dev Tests the sell function with slippage protection that succeeds despite price discrepancy.
     */
    function test_sellWithSlippageSucceeded() public {
        vm.startPrank(initialOwner, initialOwner);

        PropositionMarketPool pool = PropositionMarketPool(
            propositionMarketFactory.createContracts(
                nameAndSymbolList,
                "testtesttesttest",
                address(testTokenAddress),
                initialOwner
            )
        );

        address[] memory tokenAddressList = pool.getOptionList();

        // Mint and approve USDT
        testTokenAddress.mint(initialOwner, 100 ether);
        testTokenAddress.approve(address(pool), 100 ether);

        // 先购买一些代币
        uint256 buyTokenAmount = 5 ether;
        uint256 tokensReceived = pool.buy(
            IPropositionMarketToken(tokenAddressList[0]),
            buyTokenAmount,
            100 ether,
            block.timestamp + 3600
        );
        
        // 准备卖出所有代币
        uint256 tokensToSell = tokensReceived;
        IPropositionMarketToken(tokenAddressList[0]).approve(address(pool), tokensToSell);
        
        // 计算预期可以获得的USDT金额
        uint256 tokenPrice = pool.getExecutionPrice(tokenAddressList[0], -int256(tokensToSell));
        uint256 expectedUsdtAmount = tokenPrice.mulWad(tokensToSell);
        uint256 platformFee = expectedUsdtAmount.mulWad(pool.getPlatformFee());
        uint256 expectedUsdtNetAmount = expectedUsdtAmount.rawSub(platformFee);
        
        // 设置一个低于预期金额的最小USDT接收量，确保在可接受的滑点范围内
        uint256 minUsdtReceived = expectedUsdtNetAmount.mulWad(0.95 ether); // 允许5%的滑点
        
        // 记录交易前的余额
        uint256 tokenBalanceBefore = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 usdtBalanceBefore = testTokenAddress.balanceOf(initialOwner);
        
        // 执行卖出，预期应该成功（尽管获得的USDT可能有所不同，但会多于最小接收量）
        pool.sell(
            IPropositionMarketToken(tokenAddressList[0]),
            tokensToSell,
            minUsdtReceived, // 最小接收量
            block.timestamp + 3600
        );
        
        // 验证交易成功并获得了USDT
        uint256 tokenBalanceAfter = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 usdtBalanceAfter = testTokenAddress.balanceOf(initialOwner);
        uint256 tokensSold = tokenBalanceBefore - tokenBalanceAfter;
        uint256 usdtReceived = usdtBalanceAfter - usdtBalanceBefore;
        
        // 验证：
        // 1. 卖出的代币数量等于计划卖出的数量
        assertEq(tokensSold, tokensToSell, "Sold token amount should match the requested amount");
        
        // 2. 收到的USDT金额大于等于最小接收量（滑点保护有效）
        assertGe(usdtReceived, minUsdtReceived, "Received USDT amount should be >= minUsdtReceived");
        
        // 3. 收到的USDT金额应该接近预期金额
        assertLe(usdtReceived, expectedUsdtNetAmount.rawAdd(expectedUsdtNetAmount.mulWad(0.01 ether)), "Received USDT amount should be close to expected");
    }

    // function test_buyOption() public {

    // function buyToken() public {
    //     vm.startPrank(initialOwner, initialOwner);

    //     PropositionMarketPool pool = PropositionMarketPool(
    //         propositionMarketFactory.createContracts(
    //             nameAndSymbolList,
    //             "testtesttesttest",
    //             address(testTokenAddress),
    //             initialOwner
    //         )
    //     );

    //     address[] memory tokenAddressList = pool.getOptionList();

    //     testTokenAddress.mint(initialOwner, 100 ether);
    //     testTokenAddress.approve(address(pool), 100 ether);

    //     pool.buy(
    //         IPropositionMarketToken(IPropositionMarketToken(tokenAddressList[0])),
    //         5000000 ether,
    //         10000000 ether,
    //         block.timestamp + 3600
    //     );
    // }
}
