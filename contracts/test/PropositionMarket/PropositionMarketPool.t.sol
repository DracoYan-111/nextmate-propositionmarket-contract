// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {SSTORE2} from "solady/src/utils/SSTORE2.sol";
import {TestToken} from "../../src/PropositionMarket/utils/TestToken.sol";
import {IPropositionMarketPool} from "../../src/PropositionMarket/interfaces/IPropositionMarketPool.sol";
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

        uint256 tokenBalance = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);

        // Check pool's USDT balance before selling
        uint256 poolUsdtBalanceBefore = pool.getPayTokenAddress().balanceOf(address(pool));

        assertGt(poolUsdtBalanceBefore, 1.99 ether);

        // Approve tokens to sell all
        uint256 tokensToSell = tokenBalance;

        IPropositionMarketToken(tokenAddressList[0]).approve(address(pool), tokensToSell);

        // Get expected sell price
        uint256 expectedPrice = pool.getExecutionPrice(tokenAddressList[0], -int256(tokensToSell));

        // // uint256 usdtReceived =
        uint256 payTokenBalanceBefore = pool.getPayTokenAddress().balanceOf(address(initialOwner));
        uint256 optionTvlBefore = pool.tvl();

        pool.sell(
            IPropositionMarketToken(tokenAddressList[0]),
            tokensToSell,
            0, // No slippage protection
            block.timestamp + 3600
        );

        // Check token balance
        uint256 payTokenAmount = expectedPrice.mulWad(tokensToSell);

        uint256 tokenBalanceAfter = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);
        uint256 payTokenBalanceAfter = pool.getPayTokenAddress().balanceOf(address(initialOwner));

        assertEq(tokenBalanceAfter, 0, "Token balance should be reduced by sold amount");
        assertEq(payTokenBalanceAfter, payTokenBalanceBefore + payTokenAmount);
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
            buyToken(pool, tokenAmount, maxUsdtProvided);
        }
        uint256 tokenBalance = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);

        for (uint256 i; i < 100; ++i) {
            sellToken(pool, tokenBalance / (100));
        }
    }

    function buyToken(PropositionMarketPool pool, uint256 tokenAmount, uint256 maxUsdtProvided) public {
        vm.startPrank(initialOwner, initialOwner);

        address[] memory tokenAddressList = pool.getOptionList();

        pool.buy(
            IPropositionMarketToken(tokenAddressList[0]),
            tokenAmount,
            maxUsdtProvided,
            uint256(0),
            block.timestamp + 3600
        );
    }

    function sellToken(PropositionMarketPool pool, uint256 tokensToSell) public {
        vm.startPrank(initialOwner, initialOwner);

        address[] memory tokenAddressList = pool.getOptionList();

        pool.sell(
            IPropositionMarketToken(tokenAddressList[0]),
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
