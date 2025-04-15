// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {SSTORE2} from "solady/src/utils/SSTORE2.sol";
import {CWIA} from "solady/src/utils/legacy/CWIA.sol";
import {LibString} from "solady/src/utils/LibString.sol";

import {IPropositionMarketPool, IPropositionMarketFactory} from "./interfaces/IPropositionMarketPool.sol";

contract PropositionMarketPool is IPropositionMarketPool, CWIA {
    bool public paused;
    bool public closed;

    modifier onlyManager() {
        if (getManagerAddress() != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
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
            return fullList[fullList.length - 2];
        }
    }

    function getManagerAddress() public view returns (address) {
        unchecked {
            address dataPointer = _getArgAddress(8);
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));
            return fullList[fullList.length - 1];
        }
    }

    function getPlatformFee() external view returns (uint256) {
        return IPropositionMarketFactory(getFactoryAddress()).getPlatformFee();
    }

    function getFeeRecipient() external view returns (address) {
        return IPropositionMarketFactory(getFactoryAddress()).getFeeRecipient();
    }
}
