// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {LibClone} from "solady/src/utils/LibClone.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact draco@nextmate.ai
contract PropositionMarketToken is ERC20, Ownable {
    using LibClone for *;
    using LibString for *;

    constructor() ERC20(type(PropositionMarketToken).name, type(PropositionMarketToken).name) Ownable(address(this)) {
        _transferOwnership(address(0));
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    function owner() public view override returns (address result) {
        bytes memory args = address(this).argsOnClone(0, 20);

        assembly {
            result := shr(96, mload(add(args, 32)))
        }
        return super.owner() == address(0) ? result : super.owner();
    }

    function name() public view override returns (string memory) {
        bytes memory args = address(this).argsOnClone(20, 52);
        bytes32 result;
        assembly {
            result := mload(add(args, 32))
        }

        return result.fromSmallString();
    }

    function symbol() public view override returns (string memory) {
        bytes memory args = address(this).argsOnClone(52, 84);
        bytes32 result;
        assembly {
            result := mload(add(args, 32))
        }

        return result.fromSmallString();
    }
}
