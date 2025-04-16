// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {SSTORE2} from "solady/src/utils/SSTORE2.sol";
import {CWIA} from "solady/src/utils/legacy/CWIA.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IPropositionMarketPool, IPropositionMarketFactory} from "./interfaces/IPropositionMarketPool.sol";

contract PropositionMarketPool is IPropositionMarketPool, CWIA {
    using LibString for *;

    uint256 public totalPlatformFee;
    bool public paused;

    modifier onlyManager() {
        if (getManagerAddress() != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);
        _;
    }
    modifier whenNotPaused() {
        if (!paused) revert EnforcedPause();
        _;
    }

    function getOptionListLength() external pure returns (uint256) {
        return _getArgUint64(0);
    }

    function getOptionList() external view returns (address[] memory) {
        unchecked {
            address dataPointer = _getArgAddress(8);
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));

            address[] memory sliced = new address[](_getArgUint64(0));
            for (uint256 i = 0; i < _getArgUint64(0); ++i) {
                sliced[i] = fullList[i];
            }

            return sliced;
        }
    }

    function getFactoryAddress() public view returns (address) {
        unchecked {
            address dataPointer = _getArgAddress(8);
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));
            return fullList[fullList.length - 3];
        }
    }

    function getManagerAddress() public view returns (address) {
        unchecked {
            address dataPointer = _getArgAddress(8);
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));
            return fullList[fullList.length - 2];
        }
    }

    function getPayTokenAddress() public view returns (IERC20) {
        unchecked {
            address dataPointer = _getArgAddress(8);
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));
            return IERC20(fullList[fullList.length - 1]);
        }
    }

    function getPoolTitle() public pure returns (string memory) {
        unchecked {
            return _getArgBytes32(28).fromSmallString();
        }
    }

    function getPlatformFee() external view returns (uint256) {
        return IPropositionMarketFactory(getFactoryAddress()).getPlatformFee();
    }

    function getFeeRecipient() external view returns (address) {
        return IPropositionMarketFactory(getFactoryAddress()).getFeeRecipient();
    }

    function receivePlatformFee(address receiver) external onlyManager {
        if (totalPlatformFee == 0) revert InsufficientBalance();
        totalPlatformFee = 0;
        getPayTokenAddress().transfer(receiver, totalPlatformFee);
    }

    function pausedPool() external onlyManager {
        if (paused) revert EnforcedPause();
        emit Paused(paused = !paused);
    }
}
