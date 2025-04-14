// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Clone} from "solady/src/utils/Clone.sol";
import {IPropositionMarketPool} from "./interfaces/IPropositionMarketPool.sol";

contract PropositionMarketPool is IPropositionMarketPool, Clone {
    uint256 public lalalala = 294497;
    bool public paused;
    bool public closed;

    function optionListLength() public pure virtual returns (address) {
        return _getArgAddress(0);
    }
   function optionListLengthsss() public pure virtual returns (uint256) {
        return _getImmutableArgsOffset();
    }
    // function optionList() public pure virtual returns (address[] memory) {
    //     uint256 optionListLength256 = optionListLength();
    //     address[] memory optionTokenList = new address[](optionListLength256);
    //     uint256[] memory optionList256 = _getArgUint256Array(8, optionListLength256);
    //     for (uint256 i; i < optionListLength256; ) {
    //         optionTokenList[i] = address(uint160(optionList256[i]));
    //         unchecked {
    //             ++i;
    //         }
    //     }
    //     return optionTokenList;
    // }
}
