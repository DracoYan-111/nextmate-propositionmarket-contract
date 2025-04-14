// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {PropositionMarketFactory, FactorySettings, TokenSettings, MarketSettings} from "../../src/PropositionMarket/PropositionMarketFactory.sol";
import {PropositionMarketToken, ERC20} from "../../src/PropositionMarket/PropositionMarketToken.sol";
import {PropositionMarketPool} from "../../src/PropositionMarket/PropositionMarketPool.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract PropositionMarketFactoryTest is Test {
    PropositionMarketFactory public propositionMarketFactory;
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
    }

    /**
     * @dev Test predictDeterministicAddress
     */
    function test_predictDeterministicAddress() external {
        vm.startPrank(initialOwner, initialOwner);

        string[] memory nameAndSymbolList = new string[](4);
        nameAndSymbolList[0] = "Test Token One";
        nameAndSymbolList[1] = "TTO";
        nameAndSymbolList[2] = "Test Token Two";
        nameAndSymbolList[3] = "TTT";

        uint256 count = nameAndSymbolList.length / 2;
        address[] memory tokenPredictList = new address[](count);

        for (uint256 i = 0; i < count; i++) {
            TokenSettings memory args = TokenSettings({
                owner: address(propositionMarketFactory),
                name: nameAndSymbolList[i * 2],
                symbol: nameAndSymbolList[i * 2 + 1]
            });

            tokenPredictList[i] = propositionMarketFactory.predictDeterministicAddress(args);
        }

        address[] memory tokenAddressList = propositionMarketFactory.creatContracts(nameAndSymbolList);
        for (uint256 i; i < tokenAddressList.length; i++) {
            assertEq(tokenPredictList[i], tokenAddressList[i]);
        }

        address factoryPredictAddress = propositionMarketFactory.predictDeterministicAddress(
            MarketSettings({tokenList: tokenAddressList}),
            keccak256(abi.encodePacked(tokenAddressList))
        );

        address factoryAddress = propositionMarketFactory.creatContracts(
            MarketSettings({tokenList: tokenAddressList}),
            keccak256(abi.encodePacked(tokenAddressList))
        );

        assertEq(factoryPredictAddress, factoryAddress);
    }

    function test_creatContracts() external {
        vm.startPrank(initialOwner, initialOwner);

        string[] memory nameAndSymbolList = new string[](4);
        nameAndSymbolList[0] = "Test Token One";
        nameAndSymbolList[1] = "TTO";
        nameAndSymbolList[2] = "Test Token Two";
        nameAndSymbolList[3] = "TTT";
        address[] memory addressList = propositionMarketFactory.creatContracts(nameAndSymbolList);

        assertNotEq(addressList[0], addressList[1]);

        assertEq(ERC20(addressList[0]).name(), nameAndSymbolList[0]);
        assertEq(ERC20(addressList[1]).name(), nameAndSymbolList[2]);

        address factoryAddress = propositionMarketFactory.creatContracts(
            MarketSettings({tokenList: addressList}),
            keccak256(abi.encodePacked(addressList))
        );

        assertNotEq(factoryAddress, address(0));
    }

    function test_tokenOwner() external {
        vm.startPrank(address(propositionMarketFactory), address(propositionMarketFactory));
        string[] memory nameAndSymbolList = new string[](4);
        nameAndSymbolList[0] = "Test Token One";
        nameAndSymbolList[1] = "TTO";
        nameAndSymbolList[2] = "Test Token Two";
        nameAndSymbolList[3] = "TTT";
        address[] memory addressList = propositionMarketFactory.creatContracts(nameAndSymbolList);

        console.logAddress(PropositionMarketToken(addressList[0]).owner());
        console.logAddress(PropositionMarketToken(addressList[1]).owner());

        assertEq(PropositionMarketToken(addressList[0]).owner(), address(propositionMarketFactory));
        assertEq(PropositionMarketToken(addressList[0]).owner(), address(propositionMarketFactory));

        PropositionMarketToken(addressList[0]).mint(address((initialOwner)), 2 ether);
        PropositionMarketToken(addressList[1]).mint(address(initialOwner), 2 ether);

        PropositionMarketToken(addressList[0]).burn(address(initialOwner), 1 ether);
        PropositionMarketToken(addressList[1]).burn(address(initialOwner), 1 ether);

        assertEq(PropositionMarketToken(addressList[0]).balanceOf(initialOwner), 1 ether);
        assertEq(PropositionMarketToken(addressList[1]).balanceOf(initialOwner), 1 ether);
    }
}
