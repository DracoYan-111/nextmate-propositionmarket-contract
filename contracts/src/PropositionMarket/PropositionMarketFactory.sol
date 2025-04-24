// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {SSTORE2} from "solady/src/utils/SSTORE2.sol";
import {LibClone} from "solady/src/utils/LibClone.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import {IPropositionMarketToken, IPropositionMarketFactory, IPropositionMarketPool} from "./interfaces/IPropositionMarketFactory.sol";

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
    uint256 platformFee;
}

/// @custom:security-contact draco@nextmate.ai
contract PropositionMarketFactory is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IPropositionMarketFactory
{
    //using LibCWIA for *;
    using LibClone for *;
    using LibString for *;
    using SafeTransferLib for *;

    /// @custom:storage-location erc7201:PropositionMarketFactoryStorage
    struct PropositionMarketFactoryStorage {
        string version;
        address implementation;
        address tokenImplementation;
        FactorySettings factorySettings;
    }

    bytes32 public constant POOL_ROLE = keccak256("POOL_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // keccak256(abi.encode(uint256(keccak256("PropositionMarketFactoryStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _PROPOSITION_MARKET_FACTORY_STORAGE =
        0xca2fe85550dc2df9d90e90f9056a5a27c19809a8536e8712d438bd80180ec500;

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

        $.version = "1.0.0";
        $.implementation = _implementation;
        $.tokenImplementation = _tokenImplementation;
        $.factorySettings = _factorySettings;

        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(CREATOR_ROLE, _defaultAdmin);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setPlatformFee(uint256 newPlatformFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _getPropositionMarketFactoryStorage().factorySettings.platformFee = newPlatformFee;
    }

    function setFeeRecipient(address newFeeRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _getPropositionMarketFactoryStorage().factorySettings.feeRecipient = newFeeRecipient;
    }

    function setImplementation(address newImplementation) external onlyRole(UPGRADER_ROLE) {
        _getPropositionMarketFactoryStorage().implementation = newImplementation;
    }

    function setTokenImplementation(address newTokenImplementation) external onlyRole(UPGRADER_ROLE) {
        _getPropositionMarketFactoryStorage().tokenImplementation = newTokenImplementation;
    }

    function setImplementationVersion(string calldata version) external onlyRole(UPGRADER_ROLE) {
        _getPropositionMarketFactoryStorage().version = version;
    }

    function collectDesignatedPoolPlatformFee(
        IPropositionMarketPool[] calldata pool,
        address receiver
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < pool.length; ++i) {
            pool[i].collectPlatformFee(receiver);
        }
    }

    function pausedDesignatedPool(IPropositionMarketPool[] calldata pool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < pool.length; ++i) {
            pool[i].pausedPool();
        }
    }

    function poolUpgradeToAndCall(
        IPropositionMarketPool[] calldata pool,
        address newImplementation,
        bytes calldata data
    ) external onlyRole(UPGRADER_ROLE) {
        for (uint256 i = 0; i < pool.length; ++i) {
            pool[i].upgradeToAndCall(newImplementation, data);
        }
    }

    function emitEventTrade(
        address token,
        address trader,
        int256 tokenAmount,
        uint256 executionPrice
    ) external onlyRole(POOL_ROLE) {
        emit Trade(msg.sender, token, trader, tokenAmount, executionPrice);
    }

    function createContracts(
        TokenSettings[] memory tokenSettings,
        string calldata poolTitle,
        address payToken
    ) external returns (address pool) {
        PropositionMarketFactoryStorage storage $ = _getPropositionMarketFactoryStorage();

        address[] memory addressList = new address[](tokenSettings.length + 3);
        for (uint256 i = 0; i < tokenSettings.length; ) {
            (bytes memory tokenSettingsData, bytes32 tokenSettingsSalt) = _encodeImmutableArgs(tokenSettings[i]);
            addressList[i] = $.tokenImplementation.cloneDeterministic(tokenSettingsData, tokenSettingsSalt);
            unchecked {
                ++i;
            }
        }
        addressList[tokenSettings.length] = address(this);
        addressList[tokenSettings.length + 1] = address(this); // Reserved manager address
        addressList[tokenSettings.length + 2] = payToken;

        bytes memory addressListData = _encodeImmutableArgs(
            SSTORE2.writeCounterfactual(abi.encode(addressList), keccak256(abi.encode(addressList))),
            tokenSettings.length,
            poolTitle
        );

        pool = $.implementation.deployDeterministicERC1967(addressListData, keccak256(abi.encode(addressListData)));

        IPropositionMarketPool(pool).initialize();
        _grantRole(POOL_ROLE, pool);

        for (uint256 i = 0; i < tokenSettings.length; ) {
            IPropositionMarketToken(addressList[i]).transferOwnership(pool);
            unchecked {
                ++i;
            }
        }
        emit CreatePool(pool);
        return pool;
    }

    function getPlatformFee() external view returns (uint256) {
        return _getPropositionMarketFactoryStorage().factorySettings.platformFee;
    }

    function getFeeRecipient() external view returns (address) {
        return _getPropositionMarketFactoryStorage().factorySettings.feeRecipient;
    }

    function getImplementation() external view returns (address) {
        return _getPropositionMarketFactoryStorage().implementation;
    }

    function getTokenImplementation() external view returns (address) {
        return _getPropositionMarketFactoryStorage().tokenImplementation;
    }

    function getPoolVersion() external view returns (string memory) {
        return _getPropositionMarketFactoryStorage().version;
    }

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
        string calldata poolTitle,
        address payToken
    ) public view virtual returns (address pool) {
        unchecked {
            address[] memory oldList = predictDeterministicAddress(tokenSettings);
            uint256 len = oldList.length;

            address[] memory addressList = new address[](len + 3);

            for (uint256 i = 0; i < len; ) {
                addressList[i] = oldList[i];
                ++i;
            }

            addressList[len] = address(this);
            addressList[len + 1] = address(this);
            addressList[len + 2] = payToken;

            bytes memory addressListData = _encodeImmutableArgs(
                SSTORE2.predictCounterfactualAddress(abi.encode(addressList), keccak256(abi.encode(addressList))),
                tokenSettings.length,
                poolTitle
            );
            pool = _getPropositionMarketFactoryStorage().implementation.predictDeterministicAddressERC1967(
                addressListData,
                keccak256(abi.encode(addressListData)),
                address(this)
            );
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function _encodeImmutableArgs(TokenSettings memory args) internal view virtual returns (bytes memory, bytes32) {
        unchecked {
            return (
                abi.encodePacked(args.owner, args.name.toSmallString(), args.symbol.toSmallString()),
                keccak256(abi.encode(args.owner, args.name, args.symbol))
            );
        }
    }

    function _encodeImmutableArgs(
        address dataPointer,
        uint256 length,
        string calldata poolTitle
    ) internal view virtual returns (bytes memory) {
        unchecked {
            return
                abi.encodePacked(
                    abi.encodePacked(uint64(length)),
                    dataPointer,
                    poolTitle.toSmallString(),
                    _getPropositionMarketFactoryStorage().version.toSmallString()
                );
        }
    }

    /**
     * @dev Get PropositionMarketFactoryStorage data
     */
    function _getPropositionMarketFactoryStorage() private pure returns (PropositionMarketFactoryStorage storage $) {
        assembly {
            $.slot := _PROPOSITION_MARKET_FACTORY_STORAGE
        }
    }
}
