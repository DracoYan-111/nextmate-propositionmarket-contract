// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {SSTORE2} from "solady/src/utils/SSTORE2.sol";

import {PropositionMarketFactory, FactorySettings, TokenSettings, MarketSettings} from "../../src/PropositionMarket/PropositionMarketFactory.sol";
import {PropositionMarketToken, ERC20, Ownable} from "../../src/PropositionMarket/PropositionMarketToken.sol";
import {IPropositionMarketToken, IPropositionMarketPool, PropositionMarketPool} from "../../src/PropositionMarket/PropositionMarketPool.sol";
import {TestToken} from "../../src/PropositionMarket/utils/TestToken.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract PropositionMarketPoolTest is Test {
    PropositionMarketFactory public propositionMarketFactory;
    TokenSettings[] public nameAndSymbolList;
    TestToken public testTokenAddress;

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
                FactorySettings({feeRecipient: initialOwner, platformFee: 10})
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
            initialOwner,
            keccak256("testtesttesttest")
        );

        assertEq(PropositionMarketPool(pool).getOptionListLength(), nameAndSymbolList.length);
    }

    function test_optionList() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner,
            keccak256("testtesttesttest")
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
            initialOwner,
            keccak256("testtesttesttest")
        );

        assertEq(PropositionMarketPool(pool).getFactoryAddress(), address(propositionMarketFactory));
    }

    function test_getManagerAddress() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner,
            keccak256("testtesttesttest")
        );

        assertEq(PropositionMarketPool(pool).getManagerAddress(), initialOwner);
    }

    function test_getPoolTitle() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner,
            keccak256("testtesttesttest")
        );

        assertEq(PropositionMarketPool(pool).getPoolTitle(), "testtesttesttest");
    }

    function test_getPayTokenAddress() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner,
            keccak256("testtesttesttest")
        );

        assertEq(address(PropositionMarketPool(pool).getPayTokenAddress()), address(testTokenAddress));
    }

    function test_factorySettings() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner,
            keccak256("testtesttesttest")
        );

        assertEq(PropositionMarketPool(pool).getFeeRecipient(), address(initialOwner));
        assertEq(PropositionMarketPool(pool).getPlatformFee(), 10);
    }

    function test_receivePlatformFee() public {
        vm.startPrank(initialOwner, initialOwner);

        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner,
            keccak256("testtesttesttest")
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
            initialOwner,
            keccak256("testtesttesttest")
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

    // function test_buyOption() public {
    //     vm.startPrank(initialOwner, initialOwner);

    //     address pool = propositionMarketFactory.createContracts(
    //         nameAndSymbolList,
    //         "testtesttesttest",
    //         address(testTokenAddress),
    //         initialOwner,
    //         keccak256("testtesttesttest")
    //     );

    //     address[] memory tokenAddressList = PropositionMarketPool(pool).getOptionList();
    //             console.logUint(PropositionMarketPool(pool).buyOption(IPropositionMarketToken(tokenAddressList[0]), 0, 0));

    //     vm.startPrank(pool, pool);

    //     PropositionMarketToken(tokenAddressList[0]).mint(initialOwner, 1 ether);

    //     console.logUint(PropositionMarketPool(pool).buyOption(IPropositionMarketToken(tokenAddressList[0]), 0, 0));
    // }
}
