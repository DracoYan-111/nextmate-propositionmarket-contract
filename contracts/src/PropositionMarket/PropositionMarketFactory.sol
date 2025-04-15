// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {SSTORE2} from "solady/src/utils/SSTORE2.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {LibCWIA} from "solady/src/utils/legacy/LibCWIA.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IPropositionMarketToken, IPropositionMarketFactory} from "./interfaces/IPropositionMarketFactory.sol";

struct MarketSettings {
    address[] tokenDataList;
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

/// @custom:security-contact draco@nextmate.ai
contract PropositionMarketFactory is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IPropositionMarketFactory
{
    using LibCWIA for *;
    using LibString for *;
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

    function setPlatformFee(uint48 newPlatformFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _getPropositionMarketFactoryStorage().factorySettings.platformFee = newPlatformFee;
    }

    function setFeeRecipient(address newFeeRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _getPropositionMarketFactoryStorage().factorySettings.feeRecipient = newFeeRecipient;
    }

    function createContracts(
        TokenSettings[] memory tokenSettings,
        address manager,
        bytes32 salt
    ) external returns (address pool) {
        PropositionMarketFactoryStorage storage $ = _getPropositionMarketFactoryStorage();

        address[] memory addressList = new address[](tokenSettings.length + 2);
        for (uint256 i = 0; i < tokenSettings.length; ) {
            (bytes memory tokenSettingsData, bytes32 tokenSettingsSalt) = _encodeImmutableArgs(tokenSettings[i]);
            addressList[i] = $.tokenImplementation.cloneDeterministic(tokenSettingsData, tokenSettingsSalt);
            unchecked {
                ++i;
            }
        }
        addressList[tokenSettings.length] = address(this);
        addressList[tokenSettings.length + 1] = manager;

        bytes memory addressListData = _encodeImmutableArgs(
            SSTORE2.writeCounterfactual(abi.encode(addressList), keccak256(abi.encode(addressList))),
            tokenSettings.length
        );
        pool = $.implementation.cloneDeterministic(addressListData, salt);

        for (uint256 i = 0; i < addressList.length - 2; ) {
            IPropositionMarketToken(addressList[i]).transferOwnership(pool);
            unchecked {
                ++i;
            }
        }
        emit createPool(pool);
        return pool;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @dev Get predict deterministic address
     */
    function predictDeterministicAddress(
        TokenSettings[] calldata tokenSettings
    ) public view virtual returns (address[] memory addressList) {
        PropositionMarketFactoryStorage storage $ = _getPropositionMarketFactoryStorage();

        unchecked {
            addressList = new address[](tokenSettings.length);

            for (uint256 i = 0; i < tokenSettings.length; ) {
                (bytes memory data, bytes32 salt) = _encodeImmutableArgs(tokenSettings[i]);
                addressList[i] = $.tokenImplementation.predictDeterministicAddress(data, salt, address(this));
                ++i;
            }
        }
    }

    function predictDeterministicAddress(
        TokenSettings[] calldata tokenSettings,
        address manager,
        bytes32 salt
    ) public view virtual returns (address pool) {
        unchecked {
            address[] memory oldList = predictDeterministicAddress(tokenSettings);
            uint256 len = oldList.length;

            address[] memory addressList = new address[](len + 2);

            for (uint256 i = 0; i < len; ) {
                addressList[i] = oldList[i];
                ++i;
            }

            addressList[len] = address(this);
            addressList[len + 1] = manager;

            bytes memory addressListData = _encodeImmutableArgs(
                SSTORE2.predictCounterfactualAddress(abi.encode(addressList), keccak256(abi.encode(addressList))),
                tokenSettings.length
            );
            pool = _getPropositionMarketFactoryStorage().implementation.predictDeterministicAddress(
                addressListData,
                salt,
                address(this)
            );
        }
    }

    function _encodeImmutableArgs(TokenSettings memory args) internal view virtual returns (bytes memory, bytes32) {
        unchecked {
            return (
                abi.encodePacked(args.owner, args.name.toSmallString(), args.symbol.toSmallString()),
                keccak256(abi.encodePacked(args.owner, args.name, args.symbol))
            );
        }
    }

    function _encodeImmutableArgs(address dataPointer, uint256 length) internal view virtual returns (bytes memory) {
        unchecked {
            return abi.encodePacked(abi.encodePacked(uint64(length)), dataPointer);
        }
    }

    function predictInitCodeHash(TokenSettings[] calldata tokenSettings) external view virtual returns (bytes32) {
        address[] memory oldList = predictDeterministicAddress(tokenSettings);
        uint256 len = oldList.length;

        address[] memory addressList = new address[](len + 1);

        for (uint256 i = 0; i < len; ) {
            addressList[i] = oldList[i];
            ++i;
        }

        addressList[len] = address(this);

        bytes memory addressListData = _encodeImmutableArgs(
            SSTORE2.predictCounterfactualAddress(abi.encode(addressList), keccak256(abi.encode(addressList))),
            tokenSettings.length
        );

        return _getPropositionMarketFactoryStorage().implementation.initCodeHash(addressListData);
    }

    function getPlatformFee() external view returns (uint256) {
        return _getPropositionMarketFactoryStorage().factorySettings.platformFee;
    }

    function getFeeRecipient() external view returns (address) {
        return _getPropositionMarketFactoryStorage().factorySettings.feeRecipient;
    }

    /**
     * @dev Get PropositionMarketFactoryStorage data
     */
    function _getPropositionMarketFactoryStorage() private pure returns (PropositionMarketFactoryStorage storage $) {
        assembly {
            $.slot := PropositionMarketFactoryStorageLocation
        }
    }
}
