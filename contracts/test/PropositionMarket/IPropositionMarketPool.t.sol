// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {PropositionMarketFactory, FactorySettings, TokenSettings, MarketSettings} from "../../src/PropositionMarket/PropositionMarketFactory.sol";
import {PropositionMarketToken, ERC20} from "../../src/PropositionMarket/PropositionMarketToken.sol";
import {PropositionMarketPool} from "../../src/PropositionMarket/PropositionMarketPool.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract PropositionMarketPoolTest is Test {
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
     * @dev Test get data
     */
    function test_getData() external {
        vm.startPrank(initialOwner, initialOwner);

        string[] memory nameAndSymbolList = new string[](4);
        nameAndSymbolList[0] = "Test Token One";
        nameAndSymbolList[1] = "TTO";
        nameAndSymbolList[2] = "Test Token Two";
        nameAndSymbolList[3] = "TTT";
        address[] memory addressList = propositionMarketFactory.creatContracts(nameAndSymbolList);

        address poolAddress = propositionMarketFactory.creatContracts(
            MarketSettings({tokenList: addressList}),
            keccak256(abi.encodePacked(addressList))
        );
        bytes memory data = abi.encodePacked(address(this), uint16(20));
        console.logAddress(address(this));
        console.logBytes(data);
    }
}
