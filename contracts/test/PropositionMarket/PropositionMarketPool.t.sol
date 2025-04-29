// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {SSTORE2} from "solady/src/utils/SSTORE2.sol";
import {TestToken} from "../../src/PropositionMarket/utils/TestToken.sol";
import {IPropositionMarketPool, IPropositionMarketPool_Def} from "../../src/PropositionMarket/interfaces/IPropositionMarketPool.sol";
import {PropositionMarketToken, ERC20, Ownable} from "../../src/PropositionMarket/PropositionMarketToken.sol";
import {IPropositionMarketToken, IPropositionMarketPool_Def, PropositionMarketPool} from "../../src/PropositionMarket/PropositionMarketPool.sol";
import {PropositionMarketFactory, FactorySettings, TokenSettings, MarketSettings} from "../../src/PropositionMarket/PropositionMarketFactory.sol";

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
                FactorySettings({feeRecipient: initialOwner, platformFee: 0 ether})
            )
        );
        address proxy = address(new ERC1967Proxy(propositionMarketFactoryAddress, data));

        propositionMarketFactory = PropositionMarketFactory(proxy);

        nameAndSymbolList = new TokenSettings[](2);

        nameAndSymbolList[0].name = "Test Token One";
        nameAndSymbolList[0].symbol = "TTO";

        nameAndSymbolList[1].name = "Test Token Two";
        nameAndSymbolList[1].symbol = "TTT";
    }

    function test_optionListlength() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress)
        );

        assertEq(PropositionMarketPool(pool).getOptionListLength(), nameAndSymbolList.length);
    }

    function test_optionList() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress)
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
            address(testTokenAddress)
        );

        assertEq(PropositionMarketPool(pool).getFactoryAddress(), address(propositionMarketFactory));
    }

    function test_getPoolTitle() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress)
        );

        assertEq(PropositionMarketPool(pool).getPoolTitle(), "testtesttesttest");
    }

    function test_getPayTokenAddress() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress)
        );

        assertEq(address(PropositionMarketPool(pool).getPayTokenAddress()), address(testTokenAddress));
    }

    function test_factorySettings() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress)
        );

        assertEq(PropositionMarketPool(pool).getPlatformFee(), 0 ether);
    }

    function test_pausedPool() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress)
        );

        vm.startPrank(
            address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8),
            address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IPropositionMarketPool_Def.OwnableUnauthorizedAccount.selector,
                address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
            )
        );
        PropositionMarketPool(pool).pausedPool();

        vm.startPrank(initialOwner, initialOwner);
        IPropositionMarketPool[] memory designatedPool = new IPropositionMarketPool[](1);
        designatedPool[0] = IPropositionMarketPool(pool);
        propositionMarketFactory.pausedDesignatedPool(designatedPool);

        vm.expectRevert(abi.encodeWithSelector(IPropositionMarketPool_Def.EnforcedPause.selector));

        propositionMarketFactory.pausedDesignatedPool(designatedPool);
    }

    function test_PoolRole() public {
        vm.startPrank(initialOwner, initialOwner);

        PropositionMarketPool pool = PropositionMarketPool(
            propositionMarketFactory.createContracts(nameAndSymbolList, "testtesttesttest", address(testTokenAddress))
        );

        assertEq(propositionMarketFactory.hasRole(propositionMarketFactory.POOL_ROLE(), address(pool)), true);
    }

    /**
     * @dev Tests the single-sided buy function.
     */
    function test_buy() public returns (PropositionMarketPool) {
        vm.startPrank(initialOwner, initialOwner);

        PropositionMarketPool pool = PropositionMarketPool(
            propositionMarketFactory.createContracts(nameAndSymbolList, "testtesttesttest", address(testTokenAddress))
        );

        address[] memory tokenAddressList = pool.getOptionList();

        // Mint and approve USDT
        testTokenAddress.mint(initialOwner, 100000 ether);
        testTokenAddress.approve(address(pool), 100000 ether);

        uint256 usdtBalanceBefore = testTokenAddress.balanceOf(initialOwner);
        assertEq(usdtBalanceBefore, 100000 ether);
        uint256 tokenBalanceBefore = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        assertEq(tokenBalanceBefore, 0 ether);

        // 打印初始余额

        // Test basic buy for just one token (single-sided)
        uint256 maxUsdtProvided = 2 ether; // Max USDT to spend

        uint256 usdtForBuyingToken = maxUsdtProvided.rawSub(maxUsdtProvided.mulWad(pool.getPlatformFee()));

        // 使用approximateExecutionPrice计算可以购买的token数量和平均价格
        (uint256 tokenAmount, ) = pool.getApproximatePrice(
            tokenAddressList[0],
            usdtForBuyingToken,
            1e9, // 1/1000000000 误差
            50 // 最多50次迭代
        );

        pool.buy(
            IPropositionMarketToken(tokenAddressList[0]),
            tokenAmount,
            maxUsdtProvided,
            uint256(0),
            block.timestamp + 3600
        );

        uint256 tokenBalance = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);

        // Check token balance

        assertEq(tokenBalance, tokenAmount, "Token balance should match tokens received");

        // check usdt
        uint256 serviceFee = pool.totalPlatformFee();

        uint256 usdtReceviedForPool = pool.tvl();
        uint256 usdtBalance = testTokenAddress.balanceOf(initialOwner);
        uint256 usdtReduced = usdtBalanceBefore - usdtBalance;

        assertEq(usdtReduced, usdtReceviedForPool + serviceFee, "USDT balance should match");
        return pool;
    }

    /**
     * @dev Tests the single-sided sell function.
     */
    function test_Sell() public {
        PropositionMarketPool pool = test_buy();
        address[] memory tokenAddressList = pool.getOptionList();

        // Mint and approve USDT
        testTokenAddress.mint(initialOwner, 100 ether);
        testTokenAddress.approve(address(pool), 100 ether);

        // First buy some tokens to sell later
        uint256 buyTokenAmount = 5 ether;

        // 计算购买指定数量代币所需的USDT金额（包含平台费用）
        uint256 buyTokenPrice = pool.getExecutionPrice(tokenAddressList[0], int256(buyTokenAmount));
        uint256 baseUsdtAmount = buyTokenPrice.mulWad(buyTokenAmount);
        uint256 platformFeeAmount = baseUsdtAmount.mulWad(pool.getPlatformFee());
        uint256 totalUsdtNeeded = baseUsdtAmount.rawAdd(platformFeeAmount);

        // 记录买入前的代币余额
        uint256 tokenBalanceBefore = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);

        // 使用带有滑点保护的buy方法
        pool.buy(
            IPropositionMarketToken(tokenAddressList[0]),
            buyTokenAmount,
            totalUsdtNeeded.rawAdd(1 ether), // 额外提供一些USDT作为缓冲
            buyTokenAmount.mulWad(0.99 ether), // 设置minTokenReceived为请求数量的99%
            block.timestamp + 3600
        );

        // 计算获得的代币数量
        uint256 tokensReceived = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner) -
            tokenBalanceBefore;

        // Record balances before selling
        uint256 usdtBalanceBefore = testTokenAddress.balanceOf(initialOwner);

        // 其他记录不需要了
        // uint256 tokenBalanceBefore = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        // uint256 platformFeeBefore = pool.totalPlatformFee();
        // uint256 optionTvlBefore = pool.optionTvl(tokenAddressList[0]);
        uint256 tokenBalance = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);

        // Check pool's USDT balance before selling
        uint256 poolUsdtBalanceBefore = pool.getPayTokenAddress().balanceOf(address(pool));

        assertGt(poolUsdtBalanceBefore, 1.99 ether, "Pool USDT balance should be greater than 1.99 ether");

        // Approve tokens to sell all
        uint256 tokensToSell = tokenBalance;

        IPropositionMarketToken(tokenAddressList[0]).approve(address(pool), tokensToSell);

        // // uint256 usdtReceived =
        uint256 payTokenBalanceBefore = pool.getPayTokenAddress().balanceOf(address(initialOwner));
        uint256 optionTvlBefore = pool.tvl();

        uint256 payTokenAmount = uint256(-pool.getUsdtDelta(tokenAddressList[0], -int256(tokensToSell)));
        pool.sell(
            IPropositionMarketToken(tokenAddressList[0]),
            tokensToSell,
            0, // No slippage protection
            block.timestamp + 3600
        );

        // Check token balance
        uint256 tokenBalanceAfter = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 payTokenBalanceAfter = pool.getPayTokenAddress().balanceOf(address(initialOwner));

        assertEq(tokenBalanceAfter, 0, "Token balance should be reduced by sold amount");
        assertEq(
            payTokenBalanceAfter,
            payTokenBalanceBefore + payTokenAmount,
            "Pay token balance should increase by the expected amount"
        );
        // Check TVL change
        uint256 optionTvlAfter = pool.tvl();

        uint256 tvlDiff = optionTvlBefore - optionTvlAfter;
        assertEq(payTokenAmount, tvlDiff, "USDT received should equal TVL reduction");

        // Check pool's USDT balance after selling
        uint256 poolUsdtBalanceAfter = pool.getPayTokenAddress().balanceOf(address(pool));

        uint256 poolUsdtDiff = poolUsdtBalanceBefore - poolUsdtBalanceAfter;

        assertEq(poolUsdtDiff, payTokenAmount, "Pool USDT balance reduction should equal USDT received");

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
            propositionMarketFactory.createContracts(nameAndSymbolList, "testtesttesttest", address(testTokenAddress))
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
            abi.encodeWithSelector(
                IPropositionMarketPool_Def.SlippageFailed.selector,
                approxTokenAmount,
                minTokenReceived
            )
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
            propositionMarketFactory.createContracts(nameAndSymbolList, "testtesttesttest", address(testTokenAddress))
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
            propositionMarketFactory.createContracts(nameAndSymbolList, "testtesttesttest", address(testTokenAddress))
        );

        address[] memory tokenAddressList = pool.getOptionList();

        // Mint and approve USDT
        testTokenAddress.mint(initialOwner, 100 ether);
        testTokenAddress.approve(address(pool), 100 ether);

        // 先购买一些代币
        uint256 buyTokenAmount = 5 ether;

        // 计算购买指定数量代币所需的USDT金额（包含平台费用）
        uint256 buyTokenPrice = pool.getExecutionPrice(tokenAddressList[0], int256(buyTokenAmount));
        uint256 baseUsdtAmount = buyTokenPrice.mulWad(buyTokenAmount);
        uint256 platformFeeAmount = baseUsdtAmount.mulWad(pool.getPlatformFee());
        uint256 totalUsdtNeeded = baseUsdtAmount.rawAdd(platformFeeAmount);

        // 记录买入前的代币余额
        uint256 buyTokenBalanceBefore = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);

        // 使用带有滑点保护的buy方法
        pool.buy(
            IPropositionMarketToken(tokenAddressList[0]),
            buyTokenAmount,
            totalUsdtNeeded.rawAdd(1 ether), // 额外提供一些USDT作为缓冲
            buyTokenAmount.mulWad(0.99 ether), // 设置minTokenReceived为请求数量的99%
            block.timestamp + 3600
        );

        // 计算获得的代币数量
        uint256 tokensReceived = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner) -
            buyTokenBalanceBefore;

        // 准备卖出所有代币
        uint256 tokensToSell = tokensReceived;
        IPropositionMarketToken(tokenAddressList[0]).approve(address(pool), tokensToSell);

        // 计算预期可以获得的USDT金额
        uint256 expectedUsdtAmount = uint256(-pool.getUsdtDelta(tokenAddressList[0], -int256(tokensToSell)));
        uint256 platformFee = expectedUsdtAmount.mulWad(pool.getPlatformFee());
        uint256 expectedUsdtNetAmount = expectedUsdtAmount.rawSub(platformFee);

        // 设置一个高于预期金额的最小USDT接收量，确保会触发滑点保护
        uint256 minUsdtReceived = expectedUsdtNetAmount.rawAdd(1 ether);

        // 预期会因为滑点保护失败而回滚，并且验证错误参数
        vm.expectRevert(
            abi.encodeWithSelector(
                IPropositionMarketPool_Def.SlippageFailed.selector,
                expectedUsdtNetAmount,
                minUsdtReceived
            )
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
            propositionMarketFactory.createContracts(nameAndSymbolList, "testtesttesttest", address(testTokenAddress))
        );

        address[] memory tokenAddressList = pool.getOptionList();

        // Mint and approve USDT
        testTokenAddress.mint(initialOwner, 100 ether);
        testTokenAddress.approve(address(pool), 100 ether);

        // 先购买一些代币
        uint256 buyTokenAmount = 5 ether;

        // 计算购买指定数量代币所需的USDT金额（包含平台费用）
        uint256 buyTokenPrice = pool.getExecutionPrice(tokenAddressList[0], int256(buyTokenAmount));
        uint256 baseUsdtAmount = buyTokenPrice.mulWad(buyTokenAmount);
        uint256 platformFeeAmount = baseUsdtAmount.mulWad(pool.getPlatformFee());
        uint256 totalUsdtNeeded = baseUsdtAmount.rawAdd(platformFeeAmount);

        // 记录买入前的代币余额
        uint256 buyTokenBalanceBefore = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);

        // 使用带有滑点保护的buy方法
        pool.buy(
            IPropositionMarketToken(tokenAddressList[0]),
            buyTokenAmount,
            totalUsdtNeeded.rawAdd(1 ether), // 额外提供一些USDT作为缓冲
            buyTokenAmount.mulWad(0.99 ether), // 设置minTokenReceived为请求数量的99%
            block.timestamp + 3600
        );

        // 计算获得的代币数量
        uint256 tokensReceived = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner) -
            buyTokenBalanceBefore;

        // 准备卖出所有代币
        uint256 tokensToSell = tokensReceived;
        IPropositionMarketToken(tokenAddressList[0]).approve(address(pool), tokensToSell);

        // 计算预期可以获得的USDT金额
        uint256 sellTokenPrice = pool.getExecutionPrice(tokenAddressList[0], -int256(tokensToSell));
        uint256 expectedUsdtAmount = sellTokenPrice.mulWad(tokensToSell);
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
        assertLe(
            usdtReceived,
            expectedUsdtNetAmount.rawAdd(expectedUsdtNetAmount.mulWad(0.01 ether)),
            "Received USDT amount should be close to expected"
        );
    }

    function test_sell_slippage_revert() public {
        vm.startPrank(initialOwner, initialOwner);

        PropositionMarketPool pool = PropositionMarketPool(
            propositionMarketFactory.createContracts(nameAndSymbolList, "testtesttesttest", address(testTokenAddress))
        );
        address[] memory tokenAddressList = pool.getOptionList();

        testTokenAddress.mint(initialOwner, 100000 ether);
        testTokenAddress.approve(address(pool), 100000 ether);

        uint256 maxUsdtProvided = 2 ether;
        (uint256 tokenAmount, ) = pool.getApproximatePrice(tokenAddressList[0], maxUsdtProvided, 1e9, 50);

        pool.buy(
            IPropositionMarketToken(tokenAddressList[0]),
            tokenAmount,
            maxUsdtProvided,
            uint256(0),
            block.timestamp + 3600
        );

        uint256 tokenBalance = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        assertEq(tokenBalance, tokenAmount);

        IPropositionMarketToken(tokenAddressList[0]).approve(address(pool), tokenBalance);

        uint256 unrealisticallyHighMinUsdt = 10000 ether;

        vm.expectRevert(); // 期望revert
        pool.sell(
            IPropositionMarketToken(tokenAddressList[0]),
            tokenBalance,
            unrealisticallyHighMinUsdt,
            block.timestamp + 3600
        );
    }

    function test_buyOption() public {
        vm.startPrank(initialOwner, initialOwner);
        PropositionMarketPool pool = createContractsAndMintPayToken();
        address[] memory tokenAddressList = pool.getOptionList();

        for (uint256 i; i < 100; ++i) {
            uint256 maxUsdtProvided = 2 ether; // Max USDT to spend

            uint256 usdtForBuyingToken = maxUsdtProvided.rawSub(maxUsdtProvided.mulWad(pool.getPlatformFee()));

            // 使用approximateExecutionPrice计算可以购买的token数量和平均价格
            (uint256 tokenAmount, ) = pool.getApproximatePrice(
                tokenAddressList[0],
                usdtForBuyingToken,
                1e9, // 1/1000000000 误差
                50 // 最多50次迭代
            );
            buyToken(pool, IPropositionMarketToken(tokenAddressList[0]), tokenAmount, maxUsdtProvided);
        }
        uint256 tokenBalance = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);

        for (uint256 i; i < 100; ++i) {
            sellToken(pool, IPropositionMarketToken(tokenAddressList[0]), tokenBalance / (100));
        }
    }

    // 买N个tokenA，然后全部卖掉
    function test_BuyNTokenASell() public {
        vm.startPrank(initialOwner, initialOwner);
        PropositionMarketPool pool = createContractsAndMintPayToken();
        address[] memory tokenAddressList = pool.getOptionList();
        uint256 maxUsdtProvided = 2 ether; // Max USDT to spend

        uint256 usdtForBuyingToken = maxUsdtProvided.rawSub(maxUsdtProvided.mulWad(pool.getPlatformFee()));

        // 使用approximateExecutionPrice计算可以购买的token数量和平均价格
        (uint256 tokenAmount, ) = pool.getApproximatePrice(
            tokenAddressList[0],
            usdtForBuyingToken,
            1e9, // 1/1000000000 误差
            50 // 最多50次迭代
        );

        uint256 userUsdtBalanceBuyBefor = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBuyBefor = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancBuyeBefor = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 tvlBuyBefor = pool.tvl();

        buyToken(pool, IPropositionMarketToken(tokenAddressList[0]), tokenAmount, maxUsdtProvided);

        uint256 userUsdtBalanceBuyAfter = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBuyAfter = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancBuyAfter = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 tvlBuyAfter = pool.tvl();

        assertGt(userUsdtBalanceBuyBefor - userUsdtBalanceBuyAfter, maxUsdtProvided.mulWad(0.99 ether)); // 买入之前-买入之后 > 支付数量*0.99
        assertGt(poolUsdtBalanceBuyAfter - poolUsdtBalanceBuyBefor, maxUsdtProvided.mulWad(0.99 ether)); // 买入之后-买入之前  > 支付数量*0.99
        assertEq(userTokenBalancBuyAfter - userTokenBalancBuyeBefor, tokenAmount); // 买入之后-买入之前 = 预估数量
        assertGt(tvlBuyAfter - tvlBuyBefor, maxUsdtProvided.mulWad(0.99 ether)); // 买入之后-买入之前 > 支付数量*0.99

        sellToken(pool, IPropositionMarketToken(tokenAddressList[0]), userTokenBalancBuyAfter);

        uint256 userUsdtBalanceSellAfter = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceSellAfter = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancSellAfter = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 tvlSellAfter = pool.tvl();
        assertEq(userUsdtBalanceSellAfter, userUsdtBalanceBuyBefor); // 卖出之后 = 买入之前
        assertEq(poolUsdtBalanceSellAfter, poolUsdtBalanceBuyBefor); // 卖出之后 = 买入之前
        assertEq(userTokenBalancSellAfter, userTokenBalancBuyeBefor); // 卖出之后 = 买入之前
        assertEq(tvlSellAfter, tvlBuyBefor); // 卖出之后 = 买入之前
    }

    //买N个token A和token B，然后全部卖掉
    function test_BuyNTokenAAndBSell() public {
        vm.startPrank(initialOwner, initialOwner);
        PropositionMarketPool pool = createContractsAndMintPayToken();
        address[] memory tokenAddressList = pool.getOptionList();

        // ============ 买入token A ============
        uint256 maxUsdtProvided = 2 ether; // Max USDT to spend

        uint256 usdtForBuyingToken = maxUsdtProvided.rawSub(maxUsdtProvided.mulWad(pool.getPlatformFee()));

        // 使用approximateExecutionPrice计算可以购买的token数量和平均价格
        (uint256 tokenAmount0, ) = pool.getApproximatePrice(
            tokenAddressList[0],
            usdtForBuyingToken,
            1e9, // 1/1000000000 误差
            50 // 最多50次迭代
        );

        uint256 userUsdtBalanceBefore = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBefore = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenABalanceBefore = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 tvlBefore = pool.tvl();

        buyToken(pool, IPropositionMarketToken(tokenAddressList[0]), tokenAmount0, maxUsdtProvided);

        // ============ 买入token B ============
        (uint256 tokenAmount1, ) = pool.getApproximatePrice(
            tokenAddressList[1],
            usdtForBuyingToken,
            1e9, // 1/1000000000 误差
            50 // 最多50次迭代
        );

        buyToken(pool, IPropositionMarketToken(tokenAddressList[1]), tokenAmount1, maxUsdtProvided);

        uint256 poolUsdtBalanceAfterBuy = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userUsdtBalanceAfterBuy = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 userTokenABalanceAfterBuy = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 userTokenBBalanceAfterBuy = IPropositionMarketToken(tokenAddressList[1]).balanceOf(initialOwner);
        uint256 tvlAfterBuy = pool.tvl();

        uint256 userUsdtBalanceDiff = userUsdtBalanceBefore - userUsdtBalanceAfterBuy;

        // 验证买入后的状态
        assertEq(
            poolUsdtBalanceAfterBuy,
            userUsdtBalanceDiff,
            "Pool USDT balance should increase by 2x the provided amount"
        );
        assertEq(userTokenABalanceAfterBuy, tokenAmount0, "User should receive the expected amount of token A");
        assertEq(userTokenBBalanceAfterBuy, tokenAmount1, "User should receive the expected amount of token B");
        assertEq(tvlAfterBuy, userUsdtBalanceDiff, "TVL should increase by 2x the provided amount");

        // ============ 卖出token A ============
        sellToken(pool, IPropositionMarketToken(tokenAddressList[0]), userTokenABalanceAfterBuy);

        // ============ 卖出token B ============
        sellToken(pool, IPropositionMarketToken(tokenAddressList[1]), userTokenBBalanceAfterBuy);

        uint256 userUsdtBalanceAfterSell = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceAfterSell = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenABalanceAfterSell = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 userTokenBBalanceAfterSell = IPropositionMarketToken(tokenAddressList[1]).balanceOf(initialOwner);
        uint256 tvlAfterSell = pool.tvl();

        // 验证卖出后的状态
        assertEq(
            userUsdtBalanceAfterSell,
            userUsdtBalanceBefore,
            "User USDT balance should return to initial state after selling"
        );
        assertEq(
            poolUsdtBalanceAfterSell,
            poolUsdtBalanceBefore,
            "Pool USDT balance should return to initial state after selling"
        );
        assertEq(
            userTokenABalanceAfterSell,
            userTokenABalanceBefore,
            "User token A balance should return to initial state after selling"
        );
        assertEq(userTokenBBalanceAfterSell, 0, "User token B balance should be zero after selling all tokens");
        assertEq(tvlAfterSell, tvlBefore, "TVL should return to initial state after selling all tokens");
    }

    //买N个token A和M个token B，然后全部卖掉，（N远远大于M）
    function test_BuyNTokenAAndMBSell() public {
        vm.startPrank(initialOwner, initialOwner);
        PropositionMarketPool pool = createContractsAndMintPayToken();
        address[] memory tokenAddressList = pool.getOptionList();

        // ============ 买入大量token A ============
        uint256 maxUsdtProvided0 = 20000 ether; // Max USDT to spend

        uint256 usdtForBuyingToken0 = maxUsdtProvided0.rawSub(maxUsdtProvided0.mulWad(pool.getPlatformFee()));

        // 使用approximateExecutionPrice计算可以购买的token数量和平均价格
        (uint256 tokenAmount0, ) = pool.getApproximatePrice(
            tokenAddressList[0],
            usdtForBuyingToken0,
            1e9, // 1/1000000000 误差
            50 // 最多50次迭代
        );

        uint256 userUsdtBalanceBefore = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBefore = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenABalanceBefore = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 userTokenBBalanceBefore = IPropositionMarketToken(tokenAddressList[1]).balanceOf(initialOwner);
        uint256 tvlBefore = pool.tvl();

        buyToken(pool, IPropositionMarketToken(tokenAddressList[0]), tokenAmount0, maxUsdtProvided0);

        console.log("token0Supply", IPropositionMarketToken(tokenAddressList[0]).totalSupply());
        console.log("tvl after first buy", pool.tvl());
        console.log("pool usdt balance after first buy", pool.getPayTokenAddress().balanceOf(address(pool)));

        // ============ 买入少量token B ============
        uint256 maxUsdtProvided1 = 2 ether; // Max USDT to spend

        uint256 usdtForBuyingToken1 = maxUsdtProvided1.rawSub(maxUsdtProvided1.mulWad(pool.getPlatformFee()));

        (uint256 tokenAmount1, ) = pool.getApproximatePrice(
            tokenAddressList[1],
            usdtForBuyingToken1,
            1e9, // 1/1000000000 误差
            50 // 最多50次迭代
        );

        buyToken(pool, IPropositionMarketToken(tokenAddressList[1]), tokenAmount1, maxUsdtProvided1);

        uint256 userUsdtBalanceAfterBuy = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceAfterBuy = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenABalanceAfterBuy = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 userTokenBBalanceAfterBuy = IPropositionMarketToken(tokenAddressList[1]).balanceOf(initialOwner);
        uint256 tvlAfterBuy = pool.tvl();
        // ============ 买入后断言校验 ============
        uint256 userUsdtDiff = userUsdtBalanceBefore - userUsdtBalanceAfterBuy;
        uint256 tokenASupply = IPropositionMarketToken(tokenAddressList[0]).totalSupply();
        uint256 tokenBSupply = IPropositionMarketToken(tokenAddressList[1]).totalSupply();

        console.log("Token A supply", tokenASupply);
        console.log("Token B supply", tokenBSupply);
        console.log("Pool USDT balance", pool.getPayTokenAddress().balanceOf(address(pool)));

        assertEq(userTokenABalanceAfterBuy, tokenASupply, "Token A balance should match supply after buy");
        assertEq(userTokenBBalanceAfterBuy, tokenBSupply, "Token B balance should match supply after buy");
        assertEq(tokenASupply, tokenAmount0, "Token A supply should match estimated amount");
        assertEq(tokenBSupply, tokenAmount1, "Token B supply should match estimated amount");
        assertEq(poolUsdtBalanceAfterBuy, userUsdtDiff, "Pool USDT balance should equal user paid USDT");
        assertEq(tvlAfterBuy, userUsdtDiff, "TVL after buy should equal user paid USDT");

        // ============ 卖出 Token A ============
        sellToken(pool, IPropositionMarketToken(tokenAddressList[0]), userTokenABalanceAfterBuy);

        console.log("TVL after selling Token A", pool.tvl());
        console.log("Pool USDT after selling Token A", pool.getPayTokenAddress().balanceOf(address(pool)));

        // ============ 卖出 Token B ============
        uint256 estimatedUsdtForTokenB = pool.getExecutionPrice(
            tokenAddressList[1],
            -int256(userTokenBBalanceAfterBuy)
        );
        console.log("Estimated USDT return for Token B", estimatedUsdtForTokenB);

        sellToken(pool, IPropositionMarketToken(tokenAddressList[1]), userTokenBBalanceAfterBuy);

        // ============ 卖出后断言校验 ============
        uint256 userUsdtBalanceAfterSell = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceAfterSell = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenABalanceAfterSell = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 userTokenBBalanceAfterSell = IPropositionMarketToken(tokenAddressList[1]).balanceOf(initialOwner);
        uint256 tvlAfterSell = pool.tvl();

        assertEq(userUsdtBalanceAfterSell, userUsdtBalanceBefore, "User USDT balance after sell should equal initial");
        assertEq(poolUsdtBalanceAfterSell, poolUsdtBalanceBefore, "Pool USDT balance after sell should equal initial");
        assertEq(
            userTokenABalanceAfterSell,
            userTokenABalanceBefore,
            "Token A balance after sell should equal initial"
        );
        assertEq(
            userTokenBBalanceAfterSell,
            userTokenBBalanceBefore,
            "Token B balance after sell should equal initial"
        );
        assertEq(tvlAfterSell, tvlBefore, "TVL after sell should equal initial TVL");
    }

    //买M个token A和N个token B，然后全部卖掉，（N远远大于M）
    function test_BuyMTokenAAndNBSell() public {
        vm.startPrank(initialOwner, initialOwner);
        PropositionMarketPool pool = createContractsAndMintPayToken();
        address[] memory tokenAddressList = pool.getOptionList();

        // ============ 0 ============
        uint256 maxUsdtProvided0 = 20000 ether; // Max USDT to spend

        uint256 usdtForBuyingToken0 = maxUsdtProvided0.rawSub(maxUsdtProvided0.mulWad(pool.getPlatformFee()));

        // 使用approximateExecutionPrice计算可以购买的token数量和平均价格
        (uint256 tokenAmount0, ) = pool.getApproximatePrice(
            tokenAddressList[0],
            usdtForBuyingToken0,
            1e9, // 1/1000000000 误差
            50 // 最多50次迭代
        ); // 使用approximateExecutionPrice计算可以购买的token数量和平均价格

        uint256 userUsdtBalanceBuyBefor0 = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBuyBefor0 = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancBuyeBefor0 = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 tvlBuyBefor0 = pool.tvl();

        buyToken(pool, IPropositionMarketToken(tokenAddressList[0]), tokenAmount0, maxUsdtProvided0);

        uint256 userUsdtBalanceBuyAfter0 = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBuyAfter0 = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancBuyAfter0 = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 tvlBuyAfter0 = pool.tvl();
        // ============ end ============
        console.log("token0Supply", IPropositionMarketToken(tokenAddressList[0]).totalSupply());
        console.log("tvl after first buy", tvlBuyAfter0);
        console.log("pool usdt balance after first buy", pool.getPayTokenAddress().balanceOf(address(pool)));

        // ============ 1 ============
        uint256 maxUsdtProvided1 = 2 ether; // Max USDT to spend

        uint256 usdtForBuyingToken1 = maxUsdtProvided1.rawSub(maxUsdtProvided1.mulWad(pool.getPlatformFee()));

        (uint256 tokenAmount1, ) = pool.getApproximatePrice(
            tokenAddressList[1],
            usdtForBuyingToken1,
            1e9, // 1/1000000000 误差
            50 // 最多50次迭代
        );

        uint256 userUsdtBalanceBuyBefor1 = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBuyBefor1 = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancBuyeBefor1 = IPropositionMarketToken(tokenAddressList[1]).balanceOf(initialOwner);
        uint256 tvlBuyBefor1 = pool.tvl();

        buyToken(pool, IPropositionMarketToken(tokenAddressList[1]), tokenAmount1, maxUsdtProvided1);

        uint256 userUsdtBalanceBuyAfter1 = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBuyAfter1 = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancBuyAfter1 = IPropositionMarketToken(tokenAddressList[1]).balanceOf(initialOwner);
        uint256 tvlBuyAfter1 = pool.tvl();
        // ============ end ============

        uint256 userUsdtDiff = userUsdtBalanceBuyBefor0 - userUsdtBalanceBuyAfter1;
        uint256 userToken0Balance = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 userToken1Balance = IPropositionMarketToken(tokenAddressList[1]).balanceOf(initialOwner);
        uint256 token0Supply = IPropositionMarketToken(tokenAddressList[0]).totalSupply();
        uint256 token1Supply = IPropositionMarketToken(tokenAddressList[1]).totalSupply();
        console.log("token0Supply", token0Supply);
        console.log("token1Supply", token1Supply);
        console.log("pool usdt balance", pool.getPayTokenAddress().balanceOf(address(pool)));
        assertEq(userToken0Balance, token0Supply, "Token A balance increase should match userToken0Balance"); // 买入之后-买入之 = 预估数量0
        assertEq(userToken1Balance, token1Supply, "Token B balance increase should match userToken1Balance"); // 买入之后-买入之 = 预估数量1
        assertEq(token0Supply, tokenAmount0, "Token A supply should match estimated amount"); // 买入之后-买入之 = 预估数量0
        assertEq(token1Supply, tokenAmount1, "Token B supply should match estimated amount"); // 买入之后-买入之 = 预估数量1
        assertEq(poolUsdtBalanceBuyAfter1, userUsdtDiff, "Sum of pool USDT balances should equal user USDT provided"); // 买入之后0+买入之后 = 支付数量0+支付数量1
        assertEq(userToken0Balance, tokenAmount0, "Token A balance increase should match estimated amount"); // 买入之后-买入之 = 预估数量0
        assertEq(userToken1Balance, tokenAmount1, "Token B balance increase should match estimated amount"); // 买入之后-买入之 = 预估数量1
        assertEq(tvlBuyAfter1, userUsdtDiff, "Total TVL should equal total USDT provided"); // 买入之后 = 支付数量0+支付数量1

        sellToken(pool, IPropositionMarketToken(tokenAddressList[0]), userToken0Balance);
        console.log("pool tvl after first sell", pool.tvl());
        console.log("pool usdt after first sell", pool.getPayTokenAddress().balanceOf(address(pool)));

        // uint256 userUsdtBalanceSellAfter0 = pool.getPayTokenAddress().balanceOf(initialOwner);
        // uint256 poolUsdtBalanceSellAfter0 = pool.getPayTokenAddress().balanceOf(address(pool));
        // uint256 userTokenBalancSellAfter0 = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        // uint256 tvlSellAfter0 = pool.tvl();

        uint256 estimateUSDTNeeded = pool.getExecutionPrice(tokenAddressList[1], -int256(userToken1Balance));
        console.log("estimateUSDTNeeded", estimateUSDTNeeded);

        sellToken(pool, IPropositionMarketToken(tokenAddressList[1]), userToken1Balance);

        uint256 userUsdtBalanceSellAfter1 = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceSellAfter1 = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancSellAfter1 = IPropositionMarketToken(tokenAddressList[1]).balanceOf(initialOwner);
        uint256 tvlSellAfter1 = pool.tvl();

        assertEq(
            userUsdtBalanceSellAfter1,
            userUsdtBalanceBuyBefor0,
            "User USDT balance after selling should equal initial balance"
        ); // 卖出之后1 = 买入之前0
        assertEq(
            poolUsdtBalanceSellAfter1,
            poolUsdtBalanceBuyBefor0,
            "Pool USDT balance after selling should equal initial balance"
        ); // 卖出之后1 = 买入之前0
        assertEq(
            userTokenBalancSellAfter1,
            userTokenBalancBuyeBefor0,
            "User token balance after selling should equal initial balance"
        ); // 卖出之后1 = 买入之前-
        assertEq(tvlSellAfter1, tvlBuyBefor0, "TVL after selling should equal initial TVL"); // 卖出之后1，买入之前0
    }

    // 买N个token A和token B，然后卖掉一半A，然后再买N个token B，然后卖掉全部A，卖掉全部B
    function test_BuyNTokenAAndNBSell() public {
        vm.startPrank(initialOwner, initialOwner);
        PropositionMarketPool pool = createContractsAndMintPayToken();
        address[] memory tokenAddressList = pool.getOptionList();

        // ============ 0 ============
        uint256 maxUsdtProvided = 200 ether; // Max USDT to spend

        uint256 usdtForBuyingToken = maxUsdtProvided.rawSub(maxUsdtProvided.mulWad(pool.getPlatformFee()));

        // 使用approximateExecutionPrice计算可以购买的token数量和平均价格
        (uint256 tokenAmount0, ) = pool.getApproximatePrice(
            tokenAddressList[0],
            usdtForBuyingToken,
            1e9, // 1/1000000000 误差
            50 // 最多50次迭代
        ); // 使用approximateExecutionPrice计算可以购买的token数量和平均价格

        uint256 userUsdtBalanceBuyBefor0 = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBuyBefor0 = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancBuyeBefor0 = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 tvlBuyBefor0 = pool.tvl();

        buyToken(pool, IPropositionMarketToken(tokenAddressList[0]), tokenAmount0, maxUsdtProvided);

        uint256 userUsdtBalanceBuyAfter0 = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBuyAfter0 = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancBuyAfter0 = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 tvlBuyAfter0 = pool.tvl();
        // ============ end ============

        // ============ 1 ============
        (uint256 tokenAmount1, ) = pool.getApproximatePrice(
            tokenAddressList[1],
            usdtForBuyingToken,
            1e9, // 1/1000000000 误差
            50 // 最多50次迭代
        );

        uint256 userUsdtBalanceBuyBefor1 = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBuyBefor1 = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancBuyeBefor1 = IPropositionMarketToken(tokenAddressList[1]).balanceOf(initialOwner);
        uint256 tvlBuyBefor1 = pool.tvl();

        buyToken(pool, IPropositionMarketToken(tokenAddressList[1]), tokenAmount1, maxUsdtProvided);

        uint256 userUsdtBalanceBuyAfter1 = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBuyAfter1 = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancBuyAfter1 = IPropositionMarketToken(tokenAddressList[1]).balanceOf(initialOwner);
        uint256 tvlBuyAfter1 = pool.tvl();
        // ============ end ============

        sellToken(pool, IPropositionMarketToken(tokenAddressList[0]), userTokenBalancBuyAfter0 / 2);

        // ============ 1 ============
        (uint256 tokenAmount2, ) = pool.getApproximatePrice(
            tokenAddressList[1],
            usdtForBuyingToken,
            1e9, // 1/1000000000 误差
            50 // 最多50次迭代
        );

        uint256 userUsdtBalanceBuyBefor2 = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBuyBefor2 = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancBuyeBefor2 = IPropositionMarketToken(tokenAddressList[1]).balanceOf(initialOwner);
        uint256 tvlBuyBefor2 = pool.tvl();

        buyToken(pool, IPropositionMarketToken(tokenAddressList[1]), tokenAmount2, maxUsdtProvided);

        uint256 userUsdtBalanceBuyAfter2 = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBuyAfter2 = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancBuyAfter2 = IPropositionMarketToken(tokenAddressList[1]).balanceOf(initialOwner);
        uint256 tvlBuyAfter2 = pool.tvl();
        // ============ end ============

        uint256 userUsdtBalanceBuyAfter3 = pool.getPayTokenAddress().balanceOf(initialOwner);
        uint256 poolUsdtBalanceBuyAfter3 = pool.getPayTokenAddress().balanceOf(address(pool));
        uint256 userTokenBalancBuyAfter3 = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 tvlBuyAfter3 = pool.tvl();

        sellToken(pool, IPropositionMarketToken(tokenAddressList[0]), userTokenBalancBuyAfter3);

        sellToken(pool, IPropositionMarketToken(tokenAddressList[1]), userTokenBalancBuyAfter2);
    }

    function buyToken(
        PropositionMarketPool pool,
        IPropositionMarketToken token,
        uint256 tokenAmount,
        uint256 maxUsdtProvided
    ) public {
        vm.startPrank(initialOwner, initialOwner);

        pool.buy(token, tokenAmount, maxUsdtProvided, uint256(0), block.timestamp + 3600);
    }

    function sellToken(PropositionMarketPool pool, IPropositionMarketToken token, uint256 tokensToSell) public {
        vm.startPrank(initialOwner, initialOwner);

        pool.sell(
            token,
            tokensToSell,
            0, // No slippage protection
            block.timestamp + 3600
        );
    }

    function createContractsAndMintPayToken() public returns (PropositionMarketPool) {
        PropositionMarketPool pool = PropositionMarketPool(
            propositionMarketFactory.createContracts(nameAndSymbolList, "testtesttesttest", address(testTokenAddress))
        );
        // Mint and approve USDT
        testTokenAddress.mint(initialOwner, 100000 ether);
        testTokenAddress.approve(address(pool), 100000 ether);
        return pool;
    }
}
