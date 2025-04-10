// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {PropositionMarketFactory, FactorySettings, TokenSettings} from "../../src/PropositionMarket/PropositionMarketFactory.sol";
import {PropositionMarketToken, ERC20} from "../../src/PropositionMarket/PropositionMarketToken.sol";

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

        address toeknAddress = address(new PropositionMarketToken());

        bytes memory data = abi.encodeCall(
            PropositionMarketFactory.initialize,
            (initialOwner, address(0), toeknAddress, FactorySettings({feeRecipient: initialOwner, platformFee: 0}))
        );
        address proxy = address(new ERC1967Proxy(propositionMarketFactoryAddress, data));

        propositionMarketFactory = PropositionMarketFactory(proxy);
    }

    /**
     * @dev Test predictDeterministicAddress
     */
    function test_predictDeterministicAddress() external {
        vm.startPrank(initialOwner, initialOwner);

        address tokenAddress = propositionMarketFactory.predictDeterministicAddress(
            TokenSettings({owner: address(propositionMarketFactory), name: "Test Token One", symbol: "TTO"})
        );

        string[] memory nameAndSymbolList = new string[](2);
        nameAndSymbolList[0] = "Test Token One";
        nameAndSymbolList[1] = "TTO";
        address[] memory addressList = propositionMarketFactory.creatContracts(nameAndSymbolList);

        console.logAddress(addressList[0]);
        console.logAddress(tokenAddress);

        assertEq(tokenAddress, addressList[0]);
    }

    function test_creatContracts() external {
        vm.startPrank(initialOwner, initialOwner);

        string[] memory nameAndSymbolList = new string[](4);
        nameAndSymbolList[0] = "Test Token One";
        nameAndSymbolList[1] = "TTO";
        nameAndSymbolList[2] = "Test Token Two";
        nameAndSymbolList[3] = "TTT";
        address[] memory addressList = propositionMarketFactory.creatContracts(nameAndSymbolList);

        console.logAddress(addressList[0]);
        console.logAddress(addressList[1]);

        assertNotEq(addressList[0], addressList[1]);

        assertEq(ERC20(addressList[0]).name(), nameAndSymbolList[0]);
        assertEq(ERC20(addressList[1]).name(), nameAndSymbolList[2]);
    }
}
