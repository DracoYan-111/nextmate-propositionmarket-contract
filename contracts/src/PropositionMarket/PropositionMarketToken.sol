// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {CWIA} from "solady/src/utils/legacy/CWIA.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact draco@nextmate.ai
contract PropositionMarketToken is ERC20, Ownable, CWIA {
    using LibString for *;

    constructor() ERC20(type(PropositionMarketToken).name, type(PropositionMarketToken).name) Ownable(address(this)) {}

    function owner() public view override returns (address) {
        return super.owner() == address(0) ? _getArgAddress(0) : super.owner();
    }

    function name() public pure override returns (string memory) {
        return _getArgBytes32(20).fromSmallString();
    }

    function symbol() public pure override returns (string memory) {
        return _getArgBytes32(52).fromSmallString();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}
