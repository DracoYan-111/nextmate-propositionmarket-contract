// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {PropositionMarketFactory, FactorySettings, TokenSettings, MarketSettings} from "../../src/PropositionMarket/PropositionMarketFactory.sol";
import {PropositionMarketToken, ERC20, Ownable} from "../../src/PropositionMarket/PropositionMarketToken.sol";
import {PropositionMarketPool} from "../../src/PropositionMarket/PropositionMarketPool.sol";
import {TestToken} from "../../src/PropositionMarket/utils/TestToken.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


import {Test} from "forge-std/Test.sol";

contract PropositionMarketFactoryTest is Test {
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
                FactorySettings({feeRecipient: initialOwner, platformFee: 0})
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

    function test_predictDeterministicAddress() external {
        vm.startPrank(initialOwner, initialOwner);

        address[] memory predictTokenAddressList = propositionMarketFactory.predictDeterministicAddress(
            nameAndSymbolList
        );

        for (uint256 i; i < predictTokenAddressList.length; i++) {
            assertNotEq(predictTokenAddressList[i], address(0));
        }

        address pool = propositionMarketFactory.predictDeterministicAddress(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner
        );

        assertNotEq(pool, address(0));
    }

    function test_creatContracts() external {
        vm.startPrank(initialOwner, initialOwner);

        address predictPool = propositionMarketFactory.predictDeterministicAddress(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner
        );
        address pool = propositionMarketFactory.createContracts(
            nameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner
        );

        assertEq(pool, predictPool);

        address[] memory predictTokenAddressList = propositionMarketFactory.predictDeterministicAddress(
            nameAndSymbolList
        );

        address[] memory tokenAddressList = PropositionMarketPool(pool).getOptionList();

        for (uint256 i; i < tokenAddressList.length; i++) {
            assertEq(tokenAddressList[i], predictTokenAddressList[i]);
        }
    }

    function test_tokenOwner() external {
        vm.startPrank(initialOwner, initialOwner);
        TokenSettings[] memory newNameAndSymbolList = new TokenSettings[](1);

        newNameAndSymbolList[0].owner = address(propositionMarketFactory);
        newNameAndSymbolList[0].name = "Test Token One";
        newNameAndSymbolList[0].symbol = "TTO";

        address pool = propositionMarketFactory.createContracts(
            newNameAndSymbolList,
            "testtesttesttest",
            address(testTokenAddress),
            initialOwner
        );
        address[] memory addressList = PropositionMarketPool(pool).getOptionList();

        assertEq(PropositionMarketToken(addressList[0]).owner(), address(pool));

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, initialOwner));
        PropositionMarketToken(addressList[0]).mint(initialOwner, 1 ether);
        assertEq(PropositionMarketToken(addressList[0]).balanceOf(initialOwner), 0 ether);

        vm.startPrank(address(pool), address(pool));

        PropositionMarketToken(addressList[0]).mint(initialOwner, 1 ether);
        assertEq(PropositionMarketToken(addressList[0]).balanceOf(initialOwner), 1 ether);
    }
}
