// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {SSTORE2} from "solady/src/utils/SSTORE2.sol";

import {PropositionMarketFactory, FactorySettings, TokenSettings, MarketSettings} from "../../src/PropositionMarket/PropositionMarketFactory.sol";
import {PropositionMarketToken, ERC20, Ownable} from "../../src/PropositionMarket/PropositionMarketToken.sol";
import {IPropositionMarketToken, IPropositionMarketPool, PropositionMarketPool} from "../../src/PropositionMarket/PropositionMarketPool.sol";
import {TestToken} from "../../src/PropositionMarket/utils/TestToken.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Test} from "forge-std/Test.sol";
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

    // function test_factorySettings() public {
    //     vm.startPrank(initialOwner, initialOwner);

    //     address pool = propositionMarketFactory.createContracts(
    //         nameAndSymbolList,
    //         "testtesttesttest",
    //         address(testTokenAddress),
    //         initialOwner
    //     );

    //     assertEq(PropositionMarketPool(pool).getFeeRecipient(), address(initialOwner));
    //     assertEq(PropositionMarketPool(pool).getPlatformFee(), 0.01 ether);
    // }

    // function test_receivePlatformFee() public {
    //     vm.startPrank(initialOwner, initialOwner);

    //     address pool = propositionMarketFactory.createContracts(
    //         nameAndSymbolList,
    //         "testtesttesttest",
    //         address(testTokenAddress),
    //         initialOwner
    //     );

    //     vm.expectRevert(abi.encodeWithSelector(IPropositionMarketPool.InsufficientBalance.selector));
    //     PropositionMarketPool(pool).receivePlatformFee(initialOwner);

    //     vm.startPrank(
    //         address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8),
    //         address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
    //     );

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             IPropositionMarketPool.OwnableUnauthorizedAccount.selector,
    //             address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
    //         )
    //     );
    //     PropositionMarketPool(pool).receivePlatformFee(initialOwner);
    // }

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

    // function test_getPoolVersion() public {
    //     vm.startPrank(initialOwner, initialOwner);

    //     address pool = propositionMarketFactory.createContracts(
    //         nameAndSymbolList,
    //         "testtesttesttest",
    //         address(testTokenAddress),
    //         initialOwner
    //     );

    //     assertEq(PropositionMarketPool(pool).getPoolVersion(), propositionMarketFactory.getPoolVersion());
    // }

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

        // uint256 tokensReceived = pool.buy(
        //     IPropositionMarketToken(tokenAddressList[0]),
        //     buyTokenAmount,
        //     100 ether,
        //     block.timestamp + 3600
        // );

        // Record balances before selling
        uint256 usdtBalanceBefore = testTokenAddress.balanceOf(initialOwner);

        // uint256 tokenBalanceBefore = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);

        // uint256 platformFeeBefore = pool.totalPlatformFee();

        // uint256 optionTvlBefore = pool.optionTvl(tokenAddressList[0]);

        // Check pool's USDT balance before selling
        uint256 poolUsdtBalanceBefore = pool.getPayTokenAddress().balanceOf(address(pool));

        // Approve tokens to sell all
        // uint256 tokensToSell = tokensReceived;

        // IPropositionMarketToken(tokenAddressList[0]).approve(address(pool), tokensToSell);

        // Get expected sell price
        // uint256 expectedPrice = pool.getExecutionPrice(tokenAddressList[0], -int256(tokensToSell));

        // uint256 usdtReceived =
        // pool.sell(
        //     IPropositionMarketToken(tokenAddressList[0]),
        //     tokensToSell,
        //     0, // No slippage protection
        //     block.timestamp + 3600
        // );

        // Check token balance
        uint256 tokenBalance = IPropositionMarketToken(tokenAddressList[0]).balanceOf(initialOwner);

        // assertEq(tokenBalance, tokensReceived - tokensToSell, "Token balance should be reduced by sold amount");

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
