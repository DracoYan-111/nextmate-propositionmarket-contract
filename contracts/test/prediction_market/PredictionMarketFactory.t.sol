// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.29;

import {PredictionMarketFactory} from "../../src/prediction_market/PredictionMarketFactory.sol";
import {Test} from "forge-std/Test.sol";

contract GreeterTest is Test {
    PredictionMarketFactory public greeter;

    function setUp() public {
        greeter = new PredictionMarketFactory("Hello, Hardhat!");
    }

    function testCreateGreeter() public {
        assertEq(greeter.greet(), "Hello, Hardhat!");
        greeter.setGreeting("Hola, mundo!");
        assertEq(greeter.greet(), "Hola, mundo!");
    }
}
