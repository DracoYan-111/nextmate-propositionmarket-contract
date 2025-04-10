// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "solady/src/auth/Ownable.sol";
import {LibClone} from "solady/src/utils/LibClone.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

interface IPropositionMarketToken {
    function initialize(address initialOwner, string memory name, string memory symbol) external;
}

struct TokenSettings {
    address owner;
    string name;
    string symbol;
}

struct FactorySettings {
    address feeRecipient;
    uint48 platformFee;
}

error InvalidInput(string[]);

/// @custom:security-contact draco@nextmate.ai
contract PropositionMarketFactory is Initializable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using LibClone for *;
    using SafeTransferLib for *;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // keccak256(abi.encode(uint256(keccak256("PropositionMarketFactoryStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PropositionMarketFactoryStorageLocation =
        0x495976b1de7e08a382aaeed4d579be4f58b6ca6b75742ede148021ba1112c500;

    /// @custom:storage-location erc7201:PropositionMarketFactoryStorage
    struct PropositionMarketFactoryStorage {
        address implementation;
        address tokenImplementation;
        FactorySettings factorySettings;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _defaultAdmin,
        address _implementation,
        address _tokenImplementation,
        FactorySettings calldata _factorySettings
    ) external initializer {
        PropositionMarketFactoryStorage storage $ = _getPropositionMarketFactoryStorage();

        $.implementation = _implementation;
        $.tokenImplementation = _tokenImplementation;
        $.factorySettings = _factorySettings;

        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(CREATOR_ROLE, _defaultAdmin);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @dev Get PropositionMarketFactoryStorage data
     */
    function _getPropositionMarketFactoryStorage() private pure returns (PropositionMarketFactoryStorage storage $) {
        assembly {
            $.slot := PropositionMarketFactoryStorageLocation
        }
    }

    /**
     * @dev Get deterministic address
     */
    function predictDeterministicAddress(TokenSettings memory args) external view virtual returns (address) {
        PropositionMarketFactoryStorage storage $ = _getPropositionMarketFactoryStorage();

        return $.tokenImplementation.predictDeterministicAddress(predictInitCodeHash(args), address(this));
    }

    /**
     * @dev creat deterministic address contracts
     */
    function creatContracts(
        string[] calldata nameAndSymbolList
    ) external onlyRole(CREATOR_ROLE) returns (address[] memory addressList) {
        PropositionMarketFactoryStorage storage $ = _getPropositionMarketFactoryStorage();

        if (nameAndSymbolList.length % 2 != 0) revert InvalidInput(nameAndSymbolList);

        uint256 count = nameAndSymbolList.length / 2;
        addressList = new address[](count);

        for (uint256 i = 0; i < count; ) {
            TokenSettings memory args = TokenSettings({
                owner: address(this),
                name: nameAndSymbolList[i * 2],
                symbol: nameAndSymbolList[i * 2 + 1]
            });

            addressList[i] = $.tokenImplementation.cloneDeterministic(predictInitCodeHash(args));

            IPropositionMarketToken(addressList[i]).initialize(args.owner, args.name, args.symbol);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Get predicts the init code hash
     */
    function predictInitCodeHash(TokenSettings memory args) public view virtual returns (bytes32) {
        PropositionMarketFactoryStorage storage $ = _getPropositionMarketFactoryStorage();

        return $.tokenImplementation.initCodeHash(abi.encodePacked(args.owner, args.name, args.symbol));
    }
}
