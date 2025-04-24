// Sources flattened with hardhat v2.22.19 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol@v5.3.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reinitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Pointer to storage slot. Allows integrators to override it with a custom storage location.
     *
     * NOTE: Consider following the ERC-7201 formula to derive storage locations.
     */
    function _initializableStorageSlot() internal pure virtual returns (bytes32) {
        return INITIALIZABLE_STORAGE;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        bytes32 slot = _initializableStorageSlot();
        assembly {
            $.slot := slot
        }
    }
}

// File @openzeppelin/contracts/interfaces/draft-IERC1822.sol@v5.2.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.20;

/**
 * @dev ERC-1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// File @openzeppelin/contracts/interfaces/IERC1967.sol@v5.2.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.20;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// File @openzeppelin/contracts/proxy/beacon/IBeacon.sol@v5.2.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {UpgradeableBeacon} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// File @openzeppelin/contracts/utils/Errors.sol@v5.2.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/Errors.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of common custom errors used in multiple contracts
 *
 * IMPORTANT: Backwards compatibility is not guaranteed in future versions of the library.
 * It is recommended to avoid relying on the error API for critical functionality.
 *
 * _Available since v5.1._
 */
library Errors {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error InsufficientBalance(uint256 balance, uint256 needed);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedCall();

    /**
     * @dev The deployment failed.
     */
    error FailedDeployment();

    /**
     * @dev A necessary precompile is missing.
     */
    error MissingPrecompile(address);
}

// File @openzeppelin/contracts/utils/Address.sol@v5.2.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.2.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert Errors.InsufficientBalance(address(this).balance, amount);
        }

        (bool success, bytes memory returndata) = recipient.call{value: amount}("");
        if (!success) {
            _revert(returndata);
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {Errors.FailedCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert Errors.InsufficientBalance(address(this).balance, value);
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {Errors.FailedCall}) in case
     * of an unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {Errors.FailedCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {Errors.FailedCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            assembly ("memory-safe") {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert Errors.FailedCall();
        }
    }
}

// File @openzeppelin/contracts/utils/StorageSlot.sol@v5.2.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC-1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     // Define the slot. Alternatively, use the SlotDerivation library to derive the slot.
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * TIP: Consider using this library along with {SlotDerivation}.
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct Int256Slot {
        int256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Int256Slot` with member `value` located at `slot`.
     */
    function getInt256Slot(bytes32 slot) internal pure returns (Int256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns a `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }
}

// File @openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol@v5.2.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.2.0) (proxy/ERC1967/ERC1967Utils.sol)

pragma solidity ^0.8.22;

/**
 * @dev This library provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[ERC-1967] slots.
 */
library ERC1967Utils {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev The `implementation` of the proxy is invalid.
     */
    error ERC1967InvalidImplementation(address implementation);

    /**
     * @dev The `admin` of the proxy is invalid.
     */
    error ERC1967InvalidAdmin(address admin);

    /**
     * @dev The `beacon` of the proxy is invalid.
     */
    error ERC1967InvalidBeacon(address beacon);

    /**
     * @dev An upgrade function sees `msg.value > 0` that may be lost.
     */
    error ERC1967NonPayable();

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the ERC-1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(newImplementation);
        }
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Performs implementation upgrade with additional setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        emit IERC1967.Upgraded(newImplementation);

        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by ERC-1967) using
     * the https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the ERC-1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0)) {
            revert ERC1967InvalidAdmin(address(0));
        }
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {IERC1967-AdminChanged} event.
     */
    function changeAdmin(address newAdmin) internal {
        emit IERC1967.AdminChanged(getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is the keccak-256 hash of "eip1967.proxy.beacon" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the ERC-1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (newBeacon.code.length == 0) {
            revert ERC1967InvalidBeacon(newBeacon);
        }

        StorageSlot.getAddressSlot(BEACON_SLOT).value = newBeacon;

        address beaconImplementation = IBeacon(newBeacon).implementation();
        if (beaconImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(beaconImplementation);
        }
    }

    /**
     * @dev Change the beacon and trigger a setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-BeaconUpgraded} event.
     *
     * CAUTION: Invoking this function has no effect on an instance of {BeaconProxy} since v5, since
     * it uses an immutable beacon without looking at the value of the ERC-1967 beacon slot for
     * efficiency.
     */
    function upgradeBeaconToAndCall(address newBeacon, bytes memory data) internal {
        _setBeacon(newBeacon);
        emit IERC1967.BeaconUpgraded(newBeacon);

        if (data.length > 0) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
     * if an upgrade doesn't perform an initialization call.
     */
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert ERC1967NonPayable();
        }
    }
}

// File @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol@v5.3.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.22;

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822Proxiable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable __self = address(this);

    /**
     * @dev The version of the upgrade interface of the contract. If this getter is missing, both `upgradeTo(address)`
     * and `upgradeToAndCall(address,bytes)` are present, and `upgradeTo` must be used if no function should be called,
     * while `upgradeToAndCall` will invoke the `receive` function if the second argument is the empty byte string.
     * If the getter returns `"5.0.0"`, only `upgradeToAndCall(address,bytes)` is present, and the second argument must
     * be the empty byte string if no function should be called, making it impossible to invoke the `receive` function
     * during an upgrade.
     */
    string public constant UPGRADE_INTERFACE_VERSION = "5.0.0";

    /**
     * @dev The call is from an unauthorized context.
     */
    error UUPSUnauthorizedCallContext();

    /**
     * @dev The storage `slot` is unsupported as a UUID.
     */
    error UUPSUnsupportedProxiableUUID(bytes32 slot);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC-1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC-1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        _checkProxy();
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        _checkNotDelegated();
        _;
    }

    function __UUPSUpgradeable_init() internal onlyInitializing {}

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

    /**
     * @dev Implementation of the ERC-1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual notDelegated returns (bytes32) {
        return ERC1967Utils.IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data);
    }

    /**
     * @dev Reverts if the execution is not performed via delegatecall or the execution
     * context is not of a proxy with an ERC-1967 compliant implementation pointing to self.
     */
    function _checkProxy() internal view virtual {
        if (
            address(this) == __self || // Must be called through delegatecall
            ERC1967Utils.getImplementation() != __self // Must be called through an active proxy
        ) {
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Reverts if the execution is performed via delegatecall.
     * See {notDelegated}.
     */
    function _checkNotDelegated() internal view virtual {
        if (address(this) != __self) {
            // Must not be called through delegatecall
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev Performs an implementation upgrade with a security check for UUPS proxies, and additional setup call.
     *
     * As a security check, {proxiableUUID} is invoked in the new implementation, and the return value
     * is expected to be the implementation slot in ERC-1967.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data) private {
        try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != ERC1967Utils.IMPLEMENTATION_SLOT) {
                revert UUPSUnsupportedProxiableUUID(slot);
            }
            ERC1967Utils.upgradeToAndCall(newImplementation, data);
        } catch {
            // The implementation is not UUPS
            revert ERC1967Utils.ERC1967InvalidImplementation(newImplementation);
        }
    }
}

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v5.2.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File contracts/src/PropositionMarket/interfaces/IPropositionMarketPool.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.23;

interface IPropositionMarketPool {
    event Paused(bool);
    event Swap(
        address indexed sender,
        uint256 amountIn,
        uint256 amountOut,
        address indexed tokenIn,
        address indexed tokenOut
    );

    error EnforcedPause();
    error PaymentFailed();
    error TimeoutProhibition();
    error InsufficientBalance();
    error OwnableUnauthorizedAccount(address);
    error SlippageFailed(uint256, uint256);
    error InvalidToken();
    error ZeroQuantityError();
}

interface IPropositionMarketFactory {
    function emitEventTrade(address token, address trader, int256 tokenAmount, uint256 executionPrice) external;

    function getPlatformFee() external view returns (uint256);

    function getFeeRecipient() external view returns (address);
}

interface IPropositionMarketToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// File @openzeppelin/contracts/utils/ReentrancyGuard.sol@v5.2.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// File solady/src/utils/FixedPointMathLib.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an overflow.
    error RPowOverflow();

    /// @dev The mantissa is too big to fit.
    error MantissaOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, due to an multiplication overflow.
    error SMulWadFailed();

    /// @dev The operation failed, either due to a multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The operation failed, either due to a multiplication overflow, or a division by a zero.
    error SDivWadFailed();

    /// @dev The operation failed, either due to a multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /// @dev The input outside the acceptable domain.
    error OutOfDomain();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if gt(x, div(not(0), y)) {
                if y {
                    mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function sMulWad(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(x, y)
            // Equivalent to `require((x == 0 || z / x == y) && !(x == -1 && y == type(int256).min))`.
            if iszero(gt(or(iszero(x), eq(sdiv(z, x), y)), lt(not(x), eq(y, shl(255, 1))))) {
                mstore(0x00, 0xedcd4dd4) // `SMulWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := sdiv(z, WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded down, but without overflow checks.
    function rawMulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded down, but without overflow checks.
    function rawSMulWad(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(x, y)
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if iszero(eq(div(z, y), x)) {
                if y {
                    mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            z := add(iszero(iszero(mod(z, WAD))), div(z, WAD))
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up, but without overflow checks.
    function rawMulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && x <= type(uint256).max / WAD)`.
            if iszero(mul(y, lt(x, add(1, div(not(0), WAD))))) {
                mstore(0x00, 0x7c5f487d) // `DivWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function sDivWad(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(x, WAD)
            // Equivalent to `require(y != 0 && ((x * WAD) / WAD == x))`.
            if iszero(mul(y, eq(sdiv(z, WAD), x))) {
                mstore(0x00, 0x5c43740d) // `SDivWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := sdiv(z, y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down, but without overflow and divide by zero checks.
    function rawDivWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down, but without overflow and divide by zero checks.
    function rawSDivWad(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && x <= type(uint256).max / WAD)`.
            if iszero(mul(y, lt(x, add(1, div(not(0), WAD))))) {
                mstore(0x00, 0x7c5f487d) // `DivWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up, but without overflow and divide by zero checks.
    function rawDivWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    /// Note: This function is an approximation.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    /// Credit to Remco Bloemen under MIT license: https://2π.com/22/exp-ln
    /// Note: This function is an approximation. Monotonically increasing.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is less than 0.5 we return zero.
            // This happens when `x <= (log(1e-18) * 1e18) ~ -4.15e19`.
            if (x <= -41446531673892822313) return r;

            /// @solidity memory-safe-assembly
            assembly {
                // When the result is greater than `(2**255 - 1) / 1e18` we can not represent it as
                // an int. This happens when `x >= floor(log((2**255 - 1) / 1e18) * 1e18) ≈ 135`.
                if iszero(slt(x, 135305999368893231589)) {
                    mstore(0x00, 0xa37bfec9) // `ExpOverflow()`.
                    revert(0x1c, 0x04)
                }
            }

            // `x` is now in the range `(-42, 136) * 1e18`. Convert to `(-42, 136) * 2**96`
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // `k` is in the range `[-61, 195]`.

            // Evaluate using a (6, 7)-term rational approximation.
            // `p` is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave `p` in `2**192` basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already `2**96` too large.
                r := sdiv(p, q)
            }

            // r should be in the range `(0.09, 0.25) * 2**96`.

            // We now need to multiply r by:
            // - The scale factor `s ≈ 6.031367120`.
            // - The `2**k` factor from the range reduction.
            // - The `1e18 / 2**96` factor for base conversion.
            // We do this all at once, with an intermediate result in `2**213`
            // basis, so the final right shift is always by a positive amount.
            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    /// Credit to Remco Bloemen under MIT license: https://2π.com/22/exp-ln
    /// Note: This function is an approximation. Monotonically increasing.
    function lnWad(int256 x) internal pure returns (int256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // We want to convert `x` from `10**18` fixed point to `2**96` fixed point.
            // We do this by multiplying by `2**96 / 10**18`. But since
            // `ln(x * C) = ln(x) + ln(C)`, we can simply do nothing here
            // and add `ln(2**96 / 10**18)` at the end.

            // Compute `k = log2(x) - 96`, `r = 159 - k = 255 - log2(x) = 255 ^ log2(x)`.
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            // We place the check here for more optimal stack operations.
            if iszero(sgt(x, 0)) {
                mstore(0x00, 0x1615e638) // `LnWadUndefined()`.
                revert(0x1c, 0x04)
            }
            // forgefmt: disable-next-item
            r := xor(
                r,
                byte(
                    and(0x1f, shr(shr(r, x), 0x8421084210842108cc6318c6db6d54be)),
                    0xf8f9f9faf9fdfafbf9fdfcfdfafbfcfef9fafdfafcfcfbfefafafcfbffffffff
                )
            )

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x := shr(159, shl(r, x))

            // Evaluate using a (8, 8)-term rational approximation.
            // `p` is made monic, we will multiply by a scale factor later.
            // forgefmt: disable-next-item
            let p := sub(
                // This heavily nested expression is to avoid stack-too-deep for via-ir.
                sar(
                    96,
                    mul(
                        add(
                            43456485725739037958740375743393,
                            sar(
                                96,
                                mul(
                                    add(
                                        24828157081833163892658089445524,
                                        sar(96, mul(add(3273285459638523848632254066296, x), x))
                                    ),
                                    x
                                )
                            )
                        ),
                        x
                    )
                ),
                11111509109440967052023855526967
            )
            p := sub(sar(96, mul(p, x)), 45023709667254063763336534515857)
            p := sub(sar(96, mul(p, x)), 14706773417378608786704636184526)
            p := sub(mul(p, x), shl(96, 795164235651350426258249787498))
            // We leave `p` in `2**192` basis so we don't need to scale it back up for the division.

            // `q` is monic by convention.
            let q := add(5573035233440673466300451813936, x)
            q := add(71694874799317883764090561454958, sar(96, mul(x, q)))
            q := add(283447036172924575727196451306956, sar(96, mul(x, q)))
            q := add(401686690394027663651624208769553, sar(96, mul(x, q)))
            q := add(204048457590392012362485061816622, sar(96, mul(x, q)))
            q := add(31853899698501571402653359427138, sar(96, mul(x, q)))
            q := add(909429971244387300277376558375, sar(96, mul(x, q)))

            // `p / q` is in the range `(0, 0.125) * 2**96`.

            // Finalization, we need to:
            // - Multiply by the scale factor `s = 5.549…`.
            // - Add `ln(2**96 / 10**18)`.
            // - Add `k * ln(2)`.
            // - Multiply by `10**18 / 2**96 = 5**18 >> 78`.

            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already `2**96` too large.
            p := sdiv(p, q)
            // Multiply by the scaling factor: `s * 5**18 * 2**96`, base is now `5**18 * 2**192`.
            p := mul(1677202110996718588342820967067443963516166, p)
            // Add `ln(2) * k * 5**18 * 2**192`.
            // forgefmt: disable-next-item
            p := add(mul(16597577552685614221487285958193947469193820559219878177908093499208371, sub(159, r)), p)
            // Add `ln(2**96 / 10**18) * 5**18 * 2**192`.
            p := add(600920179829731861736702779321621459595472258049074101567377883020018308, p)
            // Base conversion: mul `2**18 / 2**192`.
            r := sar(174, p)
        }
    }

    /// @dev Returns `W_0(x)`, denominated in `WAD`.
    /// See: https://en.wikipedia.org/wiki/Lambert_W_function
    /// a.k.a. Product log function. This is an approximation of the principal branch.
    /// Note: This function is an approximation. Monotonically increasing.
    function lambertW0Wad(int256 x) internal pure returns (int256 w) {
        // forgefmt: disable-next-item
        unchecked {
            if ((w = x) <= -367879441171442322) revert OutOfDomain(); // `x` less than `-1/e`.
            (int256 wad, int256 p) = (int256(WAD), x);
            uint256 c; // Whether we need to avoid catastrophic cancellation.
            uint256 i = 4; // Number of iterations.
            if (w <= 0x1ffffffffffff) {
                if (-0x4000000000000 <= w) {
                    i = 1; // Inputs near zero only take one step to converge.
                } else if (w <= -0x3ffffffffffffff) {
                    i = 32; // Inputs near `-1/e` take very long to converge.
                }
            } else if (uint256(w >> 63) == uint256(0)) {
                /// @solidity memory-safe-assembly
                assembly {
                    // Inline log2 for more performance, since the range is small.
                    let v := shr(49, w)
                    let l := shl(3, lt(0xff, v))
                    l := add(
                        or(
                            l,
                            byte(
                                and(0x1f, shr(shr(l, v), 0x8421084210842108cc6318c6db6d54be)),
                                0x0706060506020504060203020504030106050205030304010505030400000000
                            )
                        ),
                        49
                    )
                    w := sdiv(shl(l, 7), byte(sub(l, 31), 0x0303030303030303040506080c13))
                    c := gt(l, 60)
                    i := add(2, add(gt(l, 53), c))
                }
            } else {
                int256 ll = lnWad(w = lnWad(w));
                /// @solidity memory-safe-assembly
                assembly {
                    // `w = ln(x) - ln(ln(x)) + b * ln(ln(x)) / ln(x)`.
                    w := add(sdiv(mul(ll, 1023715080943847266), w), sub(w, ll))
                    i := add(3, iszero(shr(68, x)))
                    c := iszero(shr(143, x))
                }
                if (c == uint256(0)) {
                    do {
                        // If `x` is big, use Newton's so that intermediate values won't overflow.
                        int256 e = expWad(w);
                        /// @solidity memory-safe-assembly
                        assembly {
                            let t := mul(w, div(e, wad))
                            w := sub(w, sdiv(sub(t, x), div(add(e, t), wad)))
                        }
                        if (p <= w) break;
                        p = w;
                    } while (--i != uint256(0));
                    /// @solidity memory-safe-assembly
                    assembly {
                        w := sub(w, sgt(w, 2))
                    }
                    return w;
                }
            }
            do {
                // Otherwise, use Halley's for faster convergence.
                int256 e = expWad(w);
                /// @solidity memory-safe-assembly
                assembly {
                    let t := add(w, wad)
                    let s := sub(mul(w, e), mul(x, wad))
                    w := sub(w, sdiv(mul(s, wad), sub(mul(e, t), sdiv(mul(add(t, wad), s), add(t, t)))))
                }
                if (p <= w) break;
                p = w;
            } while (--i != c);
            /// @solidity memory-safe-assembly
            assembly {
                w := sub(w, sgt(w, 2))
            }
            // For certain ranges of `x`, we'll use the quadratic-rate recursive formula of
            // R. Iacono and J.P. Boyd for the last iteration, to avoid catastrophic cancellation.
            if (c == uint256(0)) return w;
            int256 t = w | 1;
            /// @solidity memory-safe-assembly
            assembly {
                x := sdiv(mul(x, wad), t)
            }
            x = (t * (wad + lnWad(x)));
            /// @solidity memory-safe-assembly
            assembly {
                w := sdiv(x, add(wad, t))
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  GENERAL NUMBER UTILITIES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `a * b == x * y`, with full precision.
    function fullMulEq(uint256 a, uint256 b, uint256 x, uint256 y) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := and(eq(mul(a, b), mul(x, y)), eq(mulmod(x, y, not(0)), mulmod(a, b, not(0))))
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv
    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // 512-bit multiply `[p1 p0] = x * y`.
            // Compute the product mod `2**256` and mod `2**256 - 1`
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that `product = p1 * 2**256 + p0`.

            // Temporarily use `z` as `p0` to save gas.
            z := mul(x, y) // Lower 256 bits of `x * y`.
            for {

            } 1 {

            } {
                // If overflows.
                if iszero(mul(or(iszero(x), eq(div(z, x), y)), d)) {
                    let mm := mulmod(x, y, not(0))
                    let p1 := sub(mm, add(z, lt(mm, z))) // Upper 256 bits of `x * y`.

                    /*------------------- 512 by 256 division --------------------*/

                    // Make division exact by subtracting the remainder from `[p1 p0]`.
                    let r := mulmod(x, y, d) // Compute remainder using mulmod.
                    let t := and(d, sub(0, d)) // The least significant bit of `d`. `t >= 1`.
                    // Make sure `z` is less than `2**256`. Also prevents `d == 0`.
                    // Placing the check here seems to give more optimal stack operations.
                    if iszero(gt(d, p1)) {
                        mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
                        revert(0x1c, 0x04)
                    }
                    d := div(d, t) // Divide `d` by `t`, which is a power of two.
                    // Invert `d mod 2**256`
                    // Now that `d` is an odd number, it has an inverse
                    // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                    // Compute the inverse by starting with a seed that is correct
                    // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                    let inv := xor(2, mul(3, d))
                    // Now use Newton-Raphson iteration to improve the precision.
                    // Thanks to Hensel's lifting lemma, this also works in modular
                    // arithmetic, doubling the correct bits in each step.
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                    z := mul(
                        // Divide [p1 p0] by the factors of two.
                        // Shift in bits from `p1` into `p0`. For this we need
                        // to flip `t` such that it is `2**256 / t`.
                        or(mul(sub(p1, gt(r, z)), add(div(sub(0, t), t), 1)), div(sub(z, r), t)),
                        mul(sub(2, mul(d, inv)), inv) // inverse mod 2**256
                    )
                    break
                }
                z := div(z, d)
                break
            }
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision.
    /// Behavior is undefined if `d` is zero or the final result cannot fit in 256 bits.
    /// Performs the full 512 bit calculation regardless.
    function fullMulDivUnchecked(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(x, y)
            let mm := mulmod(x, y, not(0))
            let p1 := sub(mm, add(z, lt(mm, z)))
            let t := and(d, sub(0, d))
            let r := mulmod(x, y, d)
            d := div(d, t)
            let inv := xor(2, mul(3, d))
            inv := mul(inv, sub(2, mul(d, inv)))
            inv := mul(inv, sub(2, mul(d, inv)))
            inv := mul(inv, sub(2, mul(d, inv)))
            inv := mul(inv, sub(2, mul(d, inv)))
            inv := mul(inv, sub(2, mul(d, inv)))
            z := mul(
                or(mul(sub(p1, gt(r, z)), add(div(sub(0, t), t), 1)), div(sub(z, r), t)),
                mul(sub(2, mul(d, inv)), inv)
            )
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision, rounded up.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        z = fullMulDiv(x, y, d);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(x, y, d) {
                z := add(z, 1)
                if iszero(z) {
                    mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /// @dev Calculates `floor(x * y / 2 ** n)` with full precision.
    /// Throws if result overflows a uint256.
    /// Credit to Philogy under MIT license:
    /// https://github.com/SorellaLabs/angstrom/blob/main/contracts/src/libraries/X128MathLib.sol
    function fullMulDivN(uint256 x, uint256 y, uint8 n) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Temporarily use `z` as `p0` to save gas.
            z := mul(x, y) // Lower 256 bits of `x * y`. We'll call this `z`.
            for {

            } 1 {

            } {
                if iszero(or(iszero(x), eq(div(z, x), y))) {
                    let k := and(n, 0xff) // `n`, cleaned.
                    let mm := mulmod(x, y, not(0))
                    let p1 := sub(mm, add(z, lt(mm, z))) // Upper 256 bits of `x * y`.
                    //         |      p1     |      z     |
                    // Before: | p1_0 ¦ p1_1 | z_0  ¦ z_1 |
                    // Final:  |   0  ¦ p1_0 | p1_1 ¦ z_0 |
                    // Check that final `z` doesn't overflow by checking that p1_0 = 0.
                    if iszero(shr(k, p1)) {
                        z := add(shl(sub(256, k), p1), shr(k, z))
                        break
                    }
                    mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
                    revert(0x1c, 0x04)
                }
                z := shr(and(n, 0xff), z)
                break
            }
        }
    }

    /// @dev Returns `floor(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(x, y)
            // Equivalent to `require(d != 0 && (y == 0 || x <= type(uint256).max / y))`.
            if iszero(mul(or(iszero(x), eq(div(z, x), y)), d)) {
                mstore(0x00, 0xad251c27) // `MulDivFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(z, d)
        }
    }

    /// @dev Returns `ceil(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(x, y)
            // Equivalent to `require(d != 0 && (y == 0 || x <= type(uint256).max / y))`.
            if iszero(mul(or(iszero(x), eq(div(z, x), y)), d)) {
                mstore(0x00, 0xad251c27) // `MulDivFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(z, d))), div(z, d))
        }
    }

    /// @dev Returns `x`, the modular multiplicative inverse of `a`, such that `(a * x) % n == 1`.
    function invMod(uint256 a, uint256 n) internal pure returns (uint256 x) {
        /// @solidity memory-safe-assembly
        assembly {
            let g := n
            let r := mod(a, n)
            for {
                let y := 1
            } 1 {

            } {
                let q := div(g, r)
                let t := g
                g := r
                r := sub(t, mul(r, q))
                let u := x
                x := y
                y := sub(u, mul(y, q))
                if iszero(r) {
                    break
                }
            }
            x := mul(eq(g, 1), add(x, mul(slt(x, 0), n)))
        }
    }

    /// @dev Returns `ceil(x / d)`.
    /// Reverts if `d` is zero.
    function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(d) {
                mstore(0x00, 0x65244e4e) // `DivFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, d))), div(x, d))
        }
    }

    /// @dev Returns `max(0, x - y)`. Alias for `saturatingSub`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function saturatingSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns `min(2 ** 256 - 1, x + y)`.
    function saturatingAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := or(sub(0, lt(add(x, y), x)), add(x, y))
        }
    }

    /// @dev Returns `min(2 ** 256 - 1, x * y)`.
    function saturatingMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := or(sub(or(iszero(x), eq(div(mul(x, y), x), y)), 1), mul(x, y))
        }
    }

    /// @dev Returns `condition ? x : y`, without branching.
    function ternary(bool condition, uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), iszero(condition)))
        }
    }

    /// @dev Returns `condition ? x : y`, without branching.
    function ternary(bool condition, bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), iszero(condition)))
        }
    }

    /// @dev Returns `condition ? x : y`, without branching.
    function ternary(bool condition, address x, address y) internal pure returns (address z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), iszero(condition)))
        }
    }

    /// @dev Returns `x != 0 ? x : y`, without branching.
    function coalesce(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := or(x, mul(y, iszero(x)))
        }
    }

    /// @dev Returns `x != bytes32(0) ? x : y`, without branching.
    function coalesce(bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := or(x, mul(y, iszero(x)))
        }
    }

    /// @dev Returns `x != address(0) ? x : y`, without branching.
    function coalesce(address x, address y) internal pure returns (address z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := or(x, mul(y, iszero(shl(96, x))))
        }
    }

    /// @dev Exponentiate `x` to `y` by squaring, denominated in base `b`.
    /// Reverts if the computation overflows.
    function rpow(uint256 x, uint256 y, uint256 b) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(b, iszero(y)) // `0 ** 0 = 1`. Otherwise, `0 ** n = 0`.
            if x {
                z := xor(b, mul(xor(b, x), and(y, 1))) // `z = isEven(y) ? scale : x`
                let half := shr(1, b) // Divide `b` by 2.
                // Divide `y` by 2 every iteration.
                for {
                    y := shr(1, y)
                } y {
                    y := shr(1, y)
                } {
                    let xx := mul(x, x) // Store x squared.
                    let xxRound := add(xx, half) // Round to the nearest number.
                    // Revert if `xx + half` overflowed, or if `x ** 2` overflows.
                    if or(lt(xxRound, xx), shr(128, x)) {
                        mstore(0x00, 0x49f7642b) // `RPowOverflow()`.
                        revert(0x1c, 0x04)
                    }
                    x := div(xxRound, b) // Set `x` to scaled `xxRound`.
                    // If `y` is odd:
                    if and(y, 1) {
                        let zx := mul(z, x) // Compute `z * x`.
                        let zxRound := add(zx, half) // Round to the nearest number.
                        // If `z * x` overflowed or `zx + half` overflowed:
                        if or(xor(div(zx, x), z), lt(zxRound, zx)) {
                            // Revert if `x` is non-zero.
                            if x {
                                mstore(0x00, 0x49f7642b) // `RPowOverflow()`.
                                revert(0x1c, 0x04)
                            }
                        }
                        z := div(zxRound, b) // Return properly scaled `zxRound`.
                    }
                }
            }
        }
    }

    /// @dev Returns the square root of `x`, rounded down.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`. We check `y >= 2**(k + 8)`
            // but shift right by `k` bits to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the cube root of `x`, rounded down.
    /// Credit to bout3fiddy and pcaversaccio under AGPLv3 license:
    /// https://github.com/pcaversaccio/snekmate/blob/main/src/snekmate/utils/math.vy
    /// Formally verified by xuwinnie:
    /// https://github.com/vectorized/solady/blob/main/audits/xuwinnie-solady-cbrt-proof.pdf
    function cbrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            // Makeshift lookup table to nudge the approximate log2 result.
            z := div(shl(div(r, 3), shl(lt(0xf, shr(r, x)), 0xf)), xor(7, mod(r, 3)))
            // Newton-Raphson's.
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            // Round down.
            z := sub(z, lt(div(x, mul(z, z)), z))
        }
    }

    /// @dev Returns the square root of `x`, denominated in `WAD`, rounded down.
    function sqrtWad(uint256 x) internal pure returns (uint256 z) {
        unchecked {
            if (x <= type(uint256).max / 10 ** 18) return sqrt(x * 10 ** 18);
            z = (1 + sqrt(x)) * 10 ** 9;
            z = (fullMulDivUnchecked(x, 10 ** 18, z) + z) >> 1;
        }
        /// @solidity memory-safe-assembly
        assembly {
            z := sub(z, gt(999999999999999999, sub(mulmod(z, z, x), 1))) // Round down.
        }
    }

    /// @dev Returns the cube root of `x`, denominated in `WAD`, rounded down.
    /// Formally verified by xuwinnie:
    /// https://github.com/vectorized/solady/blob/main/audits/xuwinnie-solady-cbrt-proof.pdf
    function cbrtWad(uint256 x) internal pure returns (uint256 z) {
        unchecked {
            if (x <= type(uint256).max / 10 ** 36) return cbrt(x * 10 ** 36);
            z = (1 + cbrt(x)) * 10 ** 12;
            z = (fullMulDivUnchecked(x, 10 ** 36, z * z) + z + z) / 3;
        }
        /// @solidity memory-safe-assembly
        assembly {
            let p := x
            for {

            } 1 {

            } {
                if iszero(shr(229, p)) {
                    if iszero(shr(199, p)) {
                        p := mul(p, 100000000000000000) // 10 ** 17.
                        break
                    }
                    p := mul(p, 100000000) // 10 ** 8.
                    break
                }
                if iszero(shr(249, p)) {
                    p := mul(p, 100)
                }
                break
            }
            let t := mulmod(mul(z, z), z, p)
            z := sub(z, gt(lt(t, shr(1, p)), iszero(t))) // Round down.
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := 1
            if iszero(lt(x, 58)) {
                mstore(0x00, 0xaba0f2a2) // `FactorialOverflow()`.
                revert(0x1c, 0x04)
            }
            for {

            } x {
                x := sub(x, 1)
            } {
                z := mul(z, x)
            }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    /// Returns 0 if `x` is zero.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            // forgefmt: disable-next-item
            r := or(
                r,
                byte(
                    and(0x1f, shr(shr(r, x), 0x8421084210842108cc6318c6db6d54be)),
                    0x0706060506020504060203020504030106050205030304010505030400000000
                )
            )
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    /// Returns 0 if `x` is zero.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        r = log2(x);
        /// @solidity memory-safe-assembly
        assembly {
            r := add(r, lt(shl(r, 1), x))
        }
    }

    /// @dev Returns the log10 of `x`.
    /// Returns 0 if `x` is zero.
    function log10(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(x, 100000000000000000000000000000000000000)) {
                x := div(x, 100000000000000000000000000000000000000)
                r := 38
            }
            if iszero(lt(x, 100000000000000000000)) {
                x := div(x, 100000000000000000000)
                r := add(r, 20)
            }
            if iszero(lt(x, 10000000000)) {
                x := div(x, 10000000000)
                r := add(r, 10)
            }
            if iszero(lt(x, 100000)) {
                x := div(x, 100000)
                r := add(r, 5)
            }
            r := add(r, add(gt(x, 9), add(gt(x, 99), add(gt(x, 999), gt(x, 9999)))))
        }
    }

    /// @dev Returns the log10 of `x`, rounded up.
    /// Returns 0 if `x` is zero.
    function log10Up(uint256 x) internal pure returns (uint256 r) {
        r = log10(x);
        /// @solidity memory-safe-assembly
        assembly {
            r := add(r, lt(exp(10, r), x))
        }
    }

    /// @dev Returns the log256 of `x`.
    /// Returns 0 if `x` is zero.
    function log256(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(shr(3, r), lt(0xff, shr(r, x)))
        }
    }

    /// @dev Returns the log256 of `x`, rounded up.
    /// Returns 0 if `x` is zero.
    function log256Up(uint256 x) internal pure returns (uint256 r) {
        r = log256(x);
        /// @solidity memory-safe-assembly
        assembly {
            r := add(r, lt(shl(shl(3, r), 1), x))
        }
    }

    /// @dev Returns the scientific notation format `mantissa * 10 ** exponent` of `x`.
    /// Useful for compressing prices (e.g. using 25 bit mantissa and 7 bit exponent).
    function sci(uint256 x) internal pure returns (uint256 mantissa, uint256 exponent) {
        /// @solidity memory-safe-assembly
        assembly {
            mantissa := x
            if mantissa {
                if iszero(mod(mantissa, 1000000000000000000000000000000000)) {
                    mantissa := div(mantissa, 1000000000000000000000000000000000)
                    exponent := 33
                }
                if iszero(mod(mantissa, 10000000000000000000)) {
                    mantissa := div(mantissa, 10000000000000000000)
                    exponent := add(exponent, 19)
                }
                if iszero(mod(mantissa, 1000000000000)) {
                    mantissa := div(mantissa, 1000000000000)
                    exponent := add(exponent, 12)
                }
                if iszero(mod(mantissa, 1000000)) {
                    mantissa := div(mantissa, 1000000)
                    exponent := add(exponent, 6)
                }
                if iszero(mod(mantissa, 10000)) {
                    mantissa := div(mantissa, 10000)
                    exponent := add(exponent, 4)
                }
                if iszero(mod(mantissa, 100)) {
                    mantissa := div(mantissa, 100)
                    exponent := add(exponent, 2)
                }
                if iszero(mod(mantissa, 10)) {
                    mantissa := div(mantissa, 10)
                    exponent := add(exponent, 1)
                }
            }
        }
    }

    /// @dev Convenience function for packing `x` into a smaller number using `sci`.
    /// The `mantissa` will be in bits [7..255] (the upper 249 bits).
    /// The `exponent` will be in bits [0..6] (the lower 7 bits).
    /// Use `SafeCastLib` to safely ensure that the `packed` number is small
    /// enough to fit in the desired unsigned integer type:
    /// ```
    ///     uint32 packed = SafeCastLib.toUint32(FixedPointMathLib.packSci(777 ether));
    /// ```
    function packSci(uint256 x) internal pure returns (uint256 packed) {
        (x, packed) = sci(x); // Reuse for `mantissa` and `exponent`.
        /// @solidity memory-safe-assembly
        assembly {
            if shr(249, x) {
                mstore(0x00, 0xce30380c) // `MantissaOverflow()`.
                revert(0x1c, 0x04)
            }
            packed := or(shl(7, x), packed)
        }
    }

    /// @dev Convenience function for unpacking a packed number from `packSci`.
    function unpackSci(uint256 packed) internal pure returns (uint256 unpacked) {
        unchecked {
            unpacked = (packed >> 7) * 10 ** (packed & 0x7f);
        }
    }

    /// @dev Returns the average of `x` and `y`. Rounds towards zero.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = (x & y) + ((x ^ y) >> 1);
        }
    }

    /// @dev Returns the average of `x` and `y`. Rounds towards negative infinity.
    function avg(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        unchecked {
            z = (uint256(x) + uint256(x >> 255)) ^ uint256(x >> 255);
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := add(xor(sub(0, gt(x, y)), sub(y, x)), gt(x, y))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := add(xor(sub(0, sgt(x, y)), sub(y, x)), sgt(x, y))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, minValue), gt(minValue, x)))
            z := xor(z, mul(xor(z, maxValue), lt(maxValue, z)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(int256 x, int256 minValue, int256 maxValue) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, minValue), sgt(minValue, x)))
            z := xor(z, mul(xor(z, maxValue), slt(maxValue, z)))
        }
    }

    /// @dev Returns greatest common divisor of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            for {
                z := x
            } y {

            } {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /// @dev Returns `a + (b - a) * (t - begin) / (end - begin)`,
    /// with `t` clamped between `begin` and `end` (inclusive).
    /// Agnostic to the order of (`a`, `b`) and (`end`, `begin`).
    /// If `begins == end`, returns `t <= begin ? a : b`.
    function lerp(uint256 a, uint256 b, uint256 t, uint256 begin, uint256 end) internal pure returns (uint256) {
        if (begin > end) (t, begin, end) = (~t, ~begin, ~end);
        if (t <= begin) return a;
        if (t >= end) return b;
        unchecked {
            if (b >= a) return a + fullMulDiv(b - a, t - begin, end - begin);
            return a - fullMulDiv(a - b, t - begin, end - begin);
        }
    }

    /// @dev Returns `a + (b - a) * (t - begin) / (end - begin)`.
    /// with `t` clamped between `begin` and `end` (inclusive).
    /// Agnostic to the order of (`a`, `b`) and (`end`, `begin`).
    /// If `begins == end`, returns `t <= begin ? a : b`.
    function lerp(int256 a, int256 b, int256 t, int256 begin, int256 end) internal pure returns (int256) {
        if (begin > end) (t, begin, end) = (~t, ~begin, ~end);
        if (t <= begin) return a;
        if (t >= end) return b;
        // forgefmt: disable-next-item
        unchecked {
            if (b >= a)
                return int256(uint256(a) + fullMulDiv(uint256(b - a), uint256(t - begin), uint256(end - begin)));
            return int256(uint256(a) - fullMulDiv(uint256(a - b), uint256(t - begin), uint256(end - begin)));
        }
    }

    /// @dev Returns if `x` is an even number. Some people may need this.
    function isEven(uint256 x) internal pure returns (bool) {
        return x & uint256(1) == uint256(0);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   RAW NUMBER OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawSDiv(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawSMod(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := smod(x, y)
        }
    }

    /// @dev Returns `(x + y) % d`, return 0 if `d` if zero.
    function rawAddMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := addmod(x, y, d)
        }
    }

    /// @dev Returns `(x * y) % d`, return 0 if `d` if zero.
    function rawMulMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mulmod(x, y, d)
        }
    }
}

// File solady/src/utils/SafeCastLib.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe integer casting library that reverts on overflow.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
/// @dev Optimized for runtime gas for very high number of optimizer runs (i.e. >= 1000000).
library SafeCastLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to cast to the target type due to overflow.
    error Overflow();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          UNSIGNED INTEGER SAFE CASTING OPERATIONS          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Casts `x` to a uint8. Reverts on overflow.
    function toUint8(uint256 x) internal pure returns (uint8) {
        if (x >= 1 << 8) _revertOverflow();
        return uint8(x);
    }

    /// @dev Casts `x` to a uint16. Reverts on overflow.
    function toUint16(uint256 x) internal pure returns (uint16) {
        if (x >= 1 << 16) _revertOverflow();
        return uint16(x);
    }

    /// @dev Casts `x` to a uint24. Reverts on overflow.
    function toUint24(uint256 x) internal pure returns (uint24) {
        if (x >= 1 << 24) _revertOverflow();
        return uint24(x);
    }

    /// @dev Casts `x` to a uint32. Reverts on overflow.
    function toUint32(uint256 x) internal pure returns (uint32) {
        if (x >= 1 << 32) _revertOverflow();
        return uint32(x);
    }

    /// @dev Casts `x` to a uint40. Reverts on overflow.
    function toUint40(uint256 x) internal pure returns (uint40) {
        if (x >= 1 << 40) _revertOverflow();
        return uint40(x);
    }

    /// @dev Casts `x` to a uint48. Reverts on overflow.
    function toUint48(uint256 x) internal pure returns (uint48) {
        if (x >= 1 << 48) _revertOverflow();
        return uint48(x);
    }

    /// @dev Casts `x` to a uint56. Reverts on overflow.
    function toUint56(uint256 x) internal pure returns (uint56) {
        if (x >= 1 << 56) _revertOverflow();
        return uint56(x);
    }

    /// @dev Casts `x` to a uint64. Reverts on overflow.
    function toUint64(uint256 x) internal pure returns (uint64) {
        if (x >= 1 << 64) _revertOverflow();
        return uint64(x);
    }

    /// @dev Casts `x` to a uint72. Reverts on overflow.
    function toUint72(uint256 x) internal pure returns (uint72) {
        if (x >= 1 << 72) _revertOverflow();
        return uint72(x);
    }

    /// @dev Casts `x` to a uint80. Reverts on overflow.
    function toUint80(uint256 x) internal pure returns (uint80) {
        if (x >= 1 << 80) _revertOverflow();
        return uint80(x);
    }

    /// @dev Casts `x` to a uint88. Reverts on overflow.
    function toUint88(uint256 x) internal pure returns (uint88) {
        if (x >= 1 << 88) _revertOverflow();
        return uint88(x);
    }

    /// @dev Casts `x` to a uint96. Reverts on overflow.
    function toUint96(uint256 x) internal pure returns (uint96) {
        if (x >= 1 << 96) _revertOverflow();
        return uint96(x);
    }

    /// @dev Casts `x` to a uint104. Reverts on overflow.
    function toUint104(uint256 x) internal pure returns (uint104) {
        if (x >= 1 << 104) _revertOverflow();
        return uint104(x);
    }

    /// @dev Casts `x` to a uint112. Reverts on overflow.
    function toUint112(uint256 x) internal pure returns (uint112) {
        if (x >= 1 << 112) _revertOverflow();
        return uint112(x);
    }

    /// @dev Casts `x` to a uint120. Reverts on overflow.
    function toUint120(uint256 x) internal pure returns (uint120) {
        if (x >= 1 << 120) _revertOverflow();
        return uint120(x);
    }

    /// @dev Casts `x` to a uint128. Reverts on overflow.
    function toUint128(uint256 x) internal pure returns (uint128) {
        if (x >= 1 << 128) _revertOverflow();
        return uint128(x);
    }

    /// @dev Casts `x` to a uint136. Reverts on overflow.
    function toUint136(uint256 x) internal pure returns (uint136) {
        if (x >= 1 << 136) _revertOverflow();
        return uint136(x);
    }

    /// @dev Casts `x` to a uint144. Reverts on overflow.
    function toUint144(uint256 x) internal pure returns (uint144) {
        if (x >= 1 << 144) _revertOverflow();
        return uint144(x);
    }

    /// @dev Casts `x` to a uint152. Reverts on overflow.
    function toUint152(uint256 x) internal pure returns (uint152) {
        if (x >= 1 << 152) _revertOverflow();
        return uint152(x);
    }

    /// @dev Casts `x` to a uint160. Reverts on overflow.
    function toUint160(uint256 x) internal pure returns (uint160) {
        if (x >= 1 << 160) _revertOverflow();
        return uint160(x);
    }

    /// @dev Casts `x` to a uint168. Reverts on overflow.
    function toUint168(uint256 x) internal pure returns (uint168) {
        if (x >= 1 << 168) _revertOverflow();
        return uint168(x);
    }

    /// @dev Casts `x` to a uint176. Reverts on overflow.
    function toUint176(uint256 x) internal pure returns (uint176) {
        if (x >= 1 << 176) _revertOverflow();
        return uint176(x);
    }

    /// @dev Casts `x` to a uint184. Reverts on overflow.
    function toUint184(uint256 x) internal pure returns (uint184) {
        if (x >= 1 << 184) _revertOverflow();
        return uint184(x);
    }

    /// @dev Casts `x` to a uint192. Reverts on overflow.
    function toUint192(uint256 x) internal pure returns (uint192) {
        if (x >= 1 << 192) _revertOverflow();
        return uint192(x);
    }

    /// @dev Casts `x` to a uint200. Reverts on overflow.
    function toUint200(uint256 x) internal pure returns (uint200) {
        if (x >= 1 << 200) _revertOverflow();
        return uint200(x);
    }

    /// @dev Casts `x` to a uint208. Reverts on overflow.
    function toUint208(uint256 x) internal pure returns (uint208) {
        if (x >= 1 << 208) _revertOverflow();
        return uint208(x);
    }

    /// @dev Casts `x` to a uint216. Reverts on overflow.
    function toUint216(uint256 x) internal pure returns (uint216) {
        if (x >= 1 << 216) _revertOverflow();
        return uint216(x);
    }

    /// @dev Casts `x` to a uint224. Reverts on overflow.
    function toUint224(uint256 x) internal pure returns (uint224) {
        if (x >= 1 << 224) _revertOverflow();
        return uint224(x);
    }

    /// @dev Casts `x` to a uint232. Reverts on overflow.
    function toUint232(uint256 x) internal pure returns (uint232) {
        if (x >= 1 << 232) _revertOverflow();
        return uint232(x);
    }

    /// @dev Casts `x` to a uint240. Reverts on overflow.
    function toUint240(uint256 x) internal pure returns (uint240) {
        if (x >= 1 << 240) _revertOverflow();
        return uint240(x);
    }

    /// @dev Casts `x` to a uint248. Reverts on overflow.
    function toUint248(uint256 x) internal pure returns (uint248) {
        if (x >= 1 << 248) _revertOverflow();
        return uint248(x);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           SIGNED INTEGER SAFE CASTING OPERATIONS           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Casts `x` to a int8. Reverts on overflow.
    function toInt8(int256 x) internal pure returns (int8) {
        unchecked {
            if (((1 << 7) + uint256(x)) >> 8 == uint256(0)) return int8(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int16. Reverts on overflow.
    function toInt16(int256 x) internal pure returns (int16) {
        unchecked {
            if (((1 << 15) + uint256(x)) >> 16 == uint256(0)) return int16(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int24. Reverts on overflow.
    function toInt24(int256 x) internal pure returns (int24) {
        unchecked {
            if (((1 << 23) + uint256(x)) >> 24 == uint256(0)) return int24(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int32. Reverts on overflow.
    function toInt32(int256 x) internal pure returns (int32) {
        unchecked {
            if (((1 << 31) + uint256(x)) >> 32 == uint256(0)) return int32(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int40. Reverts on overflow.
    function toInt40(int256 x) internal pure returns (int40) {
        unchecked {
            if (((1 << 39) + uint256(x)) >> 40 == uint256(0)) return int40(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int48. Reverts on overflow.
    function toInt48(int256 x) internal pure returns (int48) {
        unchecked {
            if (((1 << 47) + uint256(x)) >> 48 == uint256(0)) return int48(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int56. Reverts on overflow.
    function toInt56(int256 x) internal pure returns (int56) {
        unchecked {
            if (((1 << 55) + uint256(x)) >> 56 == uint256(0)) return int56(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int64. Reverts on overflow.
    function toInt64(int256 x) internal pure returns (int64) {
        unchecked {
            if (((1 << 63) + uint256(x)) >> 64 == uint256(0)) return int64(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int72. Reverts on overflow.
    function toInt72(int256 x) internal pure returns (int72) {
        unchecked {
            if (((1 << 71) + uint256(x)) >> 72 == uint256(0)) return int72(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int80. Reverts on overflow.
    function toInt80(int256 x) internal pure returns (int80) {
        unchecked {
            if (((1 << 79) + uint256(x)) >> 80 == uint256(0)) return int80(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int88. Reverts on overflow.
    function toInt88(int256 x) internal pure returns (int88) {
        unchecked {
            if (((1 << 87) + uint256(x)) >> 88 == uint256(0)) return int88(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int96. Reverts on overflow.
    function toInt96(int256 x) internal pure returns (int96) {
        unchecked {
            if (((1 << 95) + uint256(x)) >> 96 == uint256(0)) return int96(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int104. Reverts on overflow.
    function toInt104(int256 x) internal pure returns (int104) {
        unchecked {
            if (((1 << 103) + uint256(x)) >> 104 == uint256(0)) return int104(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int112. Reverts on overflow.
    function toInt112(int256 x) internal pure returns (int112) {
        unchecked {
            if (((1 << 111) + uint256(x)) >> 112 == uint256(0)) return int112(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int120. Reverts on overflow.
    function toInt120(int256 x) internal pure returns (int120) {
        unchecked {
            if (((1 << 119) + uint256(x)) >> 120 == uint256(0)) return int120(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int128. Reverts on overflow.
    function toInt128(int256 x) internal pure returns (int128) {
        unchecked {
            if (((1 << 127) + uint256(x)) >> 128 == uint256(0)) return int128(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int136. Reverts on overflow.
    function toInt136(int256 x) internal pure returns (int136) {
        unchecked {
            if (((1 << 135) + uint256(x)) >> 136 == uint256(0)) return int136(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int144. Reverts on overflow.
    function toInt144(int256 x) internal pure returns (int144) {
        unchecked {
            if (((1 << 143) + uint256(x)) >> 144 == uint256(0)) return int144(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int152. Reverts on overflow.
    function toInt152(int256 x) internal pure returns (int152) {
        unchecked {
            if (((1 << 151) + uint256(x)) >> 152 == uint256(0)) return int152(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int160. Reverts on overflow.
    function toInt160(int256 x) internal pure returns (int160) {
        unchecked {
            if (((1 << 159) + uint256(x)) >> 160 == uint256(0)) return int160(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int168. Reverts on overflow.
    function toInt168(int256 x) internal pure returns (int168) {
        unchecked {
            if (((1 << 167) + uint256(x)) >> 168 == uint256(0)) return int168(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int176. Reverts on overflow.
    function toInt176(int256 x) internal pure returns (int176) {
        unchecked {
            if (((1 << 175) + uint256(x)) >> 176 == uint256(0)) return int176(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int184. Reverts on overflow.
    function toInt184(int256 x) internal pure returns (int184) {
        unchecked {
            if (((1 << 183) + uint256(x)) >> 184 == uint256(0)) return int184(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int192. Reverts on overflow.
    function toInt192(int256 x) internal pure returns (int192) {
        unchecked {
            if (((1 << 191) + uint256(x)) >> 192 == uint256(0)) return int192(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int200. Reverts on overflow.
    function toInt200(int256 x) internal pure returns (int200) {
        unchecked {
            if (((1 << 199) + uint256(x)) >> 200 == uint256(0)) return int200(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int208. Reverts on overflow.
    function toInt208(int256 x) internal pure returns (int208) {
        unchecked {
            if (((1 << 207) + uint256(x)) >> 208 == uint256(0)) return int208(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int216. Reverts on overflow.
    function toInt216(int256 x) internal pure returns (int216) {
        unchecked {
            if (((1 << 215) + uint256(x)) >> 216 == uint256(0)) return int216(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int224. Reverts on overflow.
    function toInt224(int256 x) internal pure returns (int224) {
        unchecked {
            if (((1 << 223) + uint256(x)) >> 224 == uint256(0)) return int224(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int232. Reverts on overflow.
    function toInt232(int256 x) internal pure returns (int232) {
        unchecked {
            if (((1 << 231) + uint256(x)) >> 232 == uint256(0)) return int232(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int240. Reverts on overflow.
    function toInt240(int256 x) internal pure returns (int240) {
        unchecked {
            if (((1 << 239) + uint256(x)) >> 240 == uint256(0)) return int240(x);
            _revertOverflow();
        }
    }

    /// @dev Casts `x` to a int248. Reverts on overflow.
    function toInt248(int256 x) internal pure returns (int248) {
        unchecked {
            if (((1 << 247) + uint256(x)) >> 248 == uint256(0)) return int248(x);
            _revertOverflow();
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               OTHER SAFE CASTING OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Casts `x` to a int8. Reverts on overflow.
    function toInt8(uint256 x) internal pure returns (int8) {
        if (x >= 1 << 7) _revertOverflow();
        return int8(int256(x));
    }

    /// @dev Casts `x` to a int16. Reverts on overflow.
    function toInt16(uint256 x) internal pure returns (int16) {
        if (x >= 1 << 15) _revertOverflow();
        return int16(int256(x));
    }

    /// @dev Casts `x` to a int24. Reverts on overflow.
    function toInt24(uint256 x) internal pure returns (int24) {
        if (x >= 1 << 23) _revertOverflow();
        return int24(int256(x));
    }

    /// @dev Casts `x` to a int32. Reverts on overflow.
    function toInt32(uint256 x) internal pure returns (int32) {
        if (x >= 1 << 31) _revertOverflow();
        return int32(int256(x));
    }

    /// @dev Casts `x` to a int40. Reverts on overflow.
    function toInt40(uint256 x) internal pure returns (int40) {
        if (x >= 1 << 39) _revertOverflow();
        return int40(int256(x));
    }

    /// @dev Casts `x` to a int48. Reverts on overflow.
    function toInt48(uint256 x) internal pure returns (int48) {
        if (x >= 1 << 47) _revertOverflow();
        return int48(int256(x));
    }

    /// @dev Casts `x` to a int56. Reverts on overflow.
    function toInt56(uint256 x) internal pure returns (int56) {
        if (x >= 1 << 55) _revertOverflow();
        return int56(int256(x));
    }

    /// @dev Casts `x` to a int64. Reverts on overflow.
    function toInt64(uint256 x) internal pure returns (int64) {
        if (x >= 1 << 63) _revertOverflow();
        return int64(int256(x));
    }

    /// @dev Casts `x` to a int72. Reverts on overflow.
    function toInt72(uint256 x) internal pure returns (int72) {
        if (x >= 1 << 71) _revertOverflow();
        return int72(int256(x));
    }

    /// @dev Casts `x` to a int80. Reverts on overflow.
    function toInt80(uint256 x) internal pure returns (int80) {
        if (x >= 1 << 79) _revertOverflow();
        return int80(int256(x));
    }

    /// @dev Casts `x` to a int88. Reverts on overflow.
    function toInt88(uint256 x) internal pure returns (int88) {
        if (x >= 1 << 87) _revertOverflow();
        return int88(int256(x));
    }

    /// @dev Casts `x` to a int96. Reverts on overflow.
    function toInt96(uint256 x) internal pure returns (int96) {
        if (x >= 1 << 95) _revertOverflow();
        return int96(int256(x));
    }

    /// @dev Casts `x` to a int104. Reverts on overflow.
    function toInt104(uint256 x) internal pure returns (int104) {
        if (x >= 1 << 103) _revertOverflow();
        return int104(int256(x));
    }

    /// @dev Casts `x` to a int112. Reverts on overflow.
    function toInt112(uint256 x) internal pure returns (int112) {
        if (x >= 1 << 111) _revertOverflow();
        return int112(int256(x));
    }

    /// @dev Casts `x` to a int120. Reverts on overflow.
    function toInt120(uint256 x) internal pure returns (int120) {
        if (x >= 1 << 119) _revertOverflow();
        return int120(int256(x));
    }

    /// @dev Casts `x` to a int128. Reverts on overflow.
    function toInt128(uint256 x) internal pure returns (int128) {
        if (x >= 1 << 127) _revertOverflow();
        return int128(int256(x));
    }

    /// @dev Casts `x` to a int136. Reverts on overflow.
    function toInt136(uint256 x) internal pure returns (int136) {
        if (x >= 1 << 135) _revertOverflow();
        return int136(int256(x));
    }

    /// @dev Casts `x` to a int144. Reverts on overflow.
    function toInt144(uint256 x) internal pure returns (int144) {
        if (x >= 1 << 143) _revertOverflow();
        return int144(int256(x));
    }

    /// @dev Casts `x` to a int152. Reverts on overflow.
    function toInt152(uint256 x) internal pure returns (int152) {
        if (x >= 1 << 151) _revertOverflow();
        return int152(int256(x));
    }

    /// @dev Casts `x` to a int160. Reverts on overflow.
    function toInt160(uint256 x) internal pure returns (int160) {
        if (x >= 1 << 159) _revertOverflow();
        return int160(int256(x));
    }

    /// @dev Casts `x` to a int168. Reverts on overflow.
    function toInt168(uint256 x) internal pure returns (int168) {
        if (x >= 1 << 167) _revertOverflow();
        return int168(int256(x));
    }

    /// @dev Casts `x` to a int176. Reverts on overflow.
    function toInt176(uint256 x) internal pure returns (int176) {
        if (x >= 1 << 175) _revertOverflow();
        return int176(int256(x));
    }

    /// @dev Casts `x` to a int184. Reverts on overflow.
    function toInt184(uint256 x) internal pure returns (int184) {
        if (x >= 1 << 183) _revertOverflow();
        return int184(int256(x));
    }

    /// @dev Casts `x` to a int192. Reverts on overflow.
    function toInt192(uint256 x) internal pure returns (int192) {
        if (x >= 1 << 191) _revertOverflow();
        return int192(int256(x));
    }

    /// @dev Casts `x` to a int200. Reverts on overflow.
    function toInt200(uint256 x) internal pure returns (int200) {
        if (x >= 1 << 199) _revertOverflow();
        return int200(int256(x));
    }

    /// @dev Casts `x` to a int208. Reverts on overflow.
    function toInt208(uint256 x) internal pure returns (int208) {
        if (x >= 1 << 207) _revertOverflow();
        return int208(int256(x));
    }

    /// @dev Casts `x` to a int216. Reverts on overflow.
    function toInt216(uint256 x) internal pure returns (int216) {
        if (x >= 1 << 215) _revertOverflow();
        return int216(int256(x));
    }

    /// @dev Casts `x` to a int224. Reverts on overflow.
    function toInt224(uint256 x) internal pure returns (int224) {
        if (x >= 1 << 223) _revertOverflow();
        return int224(int256(x));
    }

    /// @dev Casts `x` to a int232. Reverts on overflow.
    function toInt232(uint256 x) internal pure returns (int232) {
        if (x >= 1 << 231) _revertOverflow();
        return int232(int256(x));
    }

    /// @dev Casts `x` to a int240. Reverts on overflow.
    function toInt240(uint256 x) internal pure returns (int240) {
        if (x >= 1 << 239) _revertOverflow();
        return int240(int256(x));
    }

    /// @dev Casts `x` to a int248. Reverts on overflow.
    function toInt248(uint256 x) internal pure returns (int248) {
        if (x >= 1 << 247) _revertOverflow();
        return int248(int256(x));
    }

    /// @dev Casts `x` to a int256. Reverts on overflow.
    function toInt256(uint256 x) internal pure returns (int256) {
        if (int256(x) >= 0) return int256(x);
        _revertOverflow();
    }

    /// @dev Casts `x` to a uint256. Reverts on overflow.
    function toUint256(int256 x) internal pure returns (uint256) {
        if (x >= 0) return uint256(x);
        _revertOverflow();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _revertOverflow() private pure {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `Overflow()`.
            mstore(0x00, 0x35278d12)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }
    }
}

// File price/src/Price.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title Price Library
 * @notice Implements the bonding curve price calculations for the prediction market
 *
 * The library implements two main price formulas:
 *
 * 1. Spot Price Formula:
 *    P(supply) = pBase + supply / (supplyTotal + m) + k * sqrt(supply)
 *    Where:
 *    - pBase: Base price
 *    - supply: Current token supply
 *    - supplyTotal: Total supply of both tokens (supply + supplyOther)
 *    - m: Adjustment coefficient
 *    - k: Non-linear factor
 *
 * 2. Average Price Formula:
 *    avgPrice = [pBase * deltaSupply + (newSupply - supply - c * ln((newSupply + c)/(supply + c))) + (2/3) * k * (newSupply^(3/2) - supply^(3/2))] / deltaSupply
 *    Where:
 *    - deltaSupply: Change in token supply
 *    - supply: Initial supply
 *    - newSupply: Final supply (supply + deltaSupply)
 *    - c = Other token supply + m
 */
library Price {
    using FixedPointMathLib for *;
    using SafeCastLib for uint256;
    using SafeCastLib for int256;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Base price of the token (18 decimals)
    uint256 public constant pBase = 0.1 ether;

    /// @notice Adjustment coefficient to control the impact of total supply (18 decimals)
    uint256 public constant m = 1000 ether;

    /// @notice Non-linear factor for the square root term (18 decimals)
    uint256 public constant k = 0.005 ether;

    /// @notice Maximum number of iterations for the binary search
    uint256 public constant DEFAULT_MAX_ITERATIONS = 20;

    /// @notice Approximation precision for the binary search
    uint256 public constant DEFAULT_APPROXIMATION_PRECISION = 1e3;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    error NegativePrice(int256 price);
    error InsufficientSupply(int256 supply);
    error ApproximationFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        PRICE FORMULAS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    /**
     * @notice Calculates the spot price based on current token supplies
     * @param supply Current token supply (18 decimals)
     * @param supplyOther Supply of the paired token (18 decimals)
     * @return The calculated spot price in USDT (6 decimals)
     * @dev Implements P(supply) = pBase + supply / (supplyTotal + m) + k * sqrt(supply)
     */
    function getSpotPrice(uint256 supply, uint256 supplyOther) public pure returns (uint256) {
        uint256 supplyTotal = supply + supplyOther;
        uint256 denominator = supplyTotal + m;

        // Calculate linear term: supply / (supplyTotal + m)
        uint256 linearTerm = supply.divWad(denominator);

        // Calculate square root term: k * sqrt(supply)
        uint256 sqrtTerm = k.mulWad(supply.sqrtWad());

        return pBase + linearTerm + sqrtTerm;
    }

    /**
     * @notice Calculates the average price for a given change in token supply
     * @param supply Initial token supply (18 decimals)
     * @param supplyOther Supply of the paired token (18 decimals)
     * @param deltaSupply Change in token supply (18 decimals), positive for buying, negative for selling
     * @return price The calculated average price in USDT (6 decimals)
     * @dev Implements the integral formula for average price calculation
     */
    function getExecutionPrice(uint256 supply, uint256 supplyOther, int256 deltaSupply) public pure returns (uint256) {
        // condition check
        if (deltaSupply == 0) return getSpotPrice(supply, supplyOther);

        if (supply.toInt256() + deltaSupply < 0) revert InsufficientSupply(supply.toInt256() + deltaSupply);

        uint256 newSupply = deltaSupply > 0 ? supply + deltaSupply.toUint256() : supply - (-deltaSupply).toUint256();
        uint256 c = supplyOther + m;

        // Calculate ln((newSupply + c)/(supply + c))
        uint256 ratio = (newSupply + c).divWad(supply + c);

        int256 lnTerm = ratio.toInt256().lnWad();

        // Calculate integral term: newSupply - supply - c * ln((newSupply + c)/(supply + c))
        int256 integralTerm = newSupply.toInt256() - supply.toInt256() - c.toInt256().sMulWad(lnTerm);

        // Calculate square root integral term: (2/3) * k * (newSupply^(3/2) - supply^(3/2))
        int256 sqrtIntegral = (2 * k).toInt256().sMulWad(
            (newSupply.sqrtWad().mulWad(newSupply).toInt256() - supply.sqrtWad().mulWad(supply).toInt256()) / 3
        );

        // Calculate final average price
        int256 price = (pBase.toInt256().sMulWad(deltaSupply) + integralTerm + sqrtIntegral).sDivWad(deltaSupply);
        if (price < 0) revert NegativePrice(price);

        // Convert final price from 18 decimals to 6 decimals USDT
        return price.toUint256();
    }

    /**
     * @notice Calculate the token amount and average price that can be purchased with a given USDT amount
     * @param supply Current token supply (18 decimals)
     * @param supplyOther Supply of the paired token (18 decimals)
     * @param usdtAmount USDT amount provided by user (already in 6 decimals)
     * @param approxPrecision Approximation precision
     * @param maxIteration Maximum number of iterations
     * @return tokenAmount Calculated token amount (18 decimals)
     * @return avgPrice Average price (6 decimals)
     * @dev Uses binary search combined with getAveragePrice function
     */
    function approximateExecutionPrice(
        uint256 supply,
        uint256 supplyOther,
        uint256 usdtAmount,
        uint256 approxPrecision,
        uint256 maxIteration
    ) public pure returns (uint256 tokenAmount, uint256 avgPrice) {
        // Set binary search bounds (based on current price and new price)
        // Buying case, price will increase
        uint256 upperBound = supply + usdtAmount.divWad(getSpotPrice(supply, supplyOther));
        uint256 lowerBound = supply;

        // Set precision requirement 1/1000
        int256 precision = (usdtAmount / approxPrecision).toInt256();

        // Add iteration limit
        uint iterations = 0;

        // Perform binary search
        while (iterations < maxIteration) {
            uint256 mid = (lowerBound + upperBound) / 2;
            uint256 supplyDelta = mid - supply;

            // Calculate average price for mid amount of tokens
            uint256 price = getExecutionPrice(supply, supplyOther, supplyDelta.toInt256());

            // Calculate total value (USDT, 6 decimals)
            uint256 totalValue = price.mulWad(supplyDelta);
            int256 usdtDiff = usdtAmount.toInt256() - totalValue.toInt256();

            if (totalValue < usdtAmount) {
                lowerBound = mid;
            } else if (totalValue > usdtAmount) {
                upperBound = mid;
            } else {
                // Found exact match
                return (supplyDelta, price);
            }

            if (usdtDiff > 0 && usdtDiff <= precision) return (supplyDelta, price);

            // Increment iteration count
            iterations++;
        }

        revert ApproximationFailed();
    }

    /**
     * @notice Convenience method to calculate token amount and price using default precision and iteration parameters
     * @param supply Current token supply (18 decimals)
     * @param supplyOther Supply of the paired token (18 decimals)
     * @param usdtAmount USDT amount provided by user (6 decimals)
     * @return tokenAmount Calculated token amount (18 decimals)
     * @return avgPrice Average price (6 decimals)
     */
    function approximateExecutionPrice(
        uint256 supply,
        uint256 supplyOther,
        uint256 usdtAmount
    ) public pure returns (uint256 tokenAmount, uint256 avgPrice) {
        return
            approximateExecutionPrice(
                supply,
                supplyOther,
                usdtAmount,
                DEFAULT_APPROXIMATION_PRECISION,
                DEFAULT_MAX_ITERATIONS
            );
    }
}

// File solady/src/utils/LibClone.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Minimal proxy library.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibClone.sol)
/// @author Minimal proxy by 0age (https://github.com/0age)
/// @author Clones with immutable args by wighawag, zefram.eth, Saw-mon & Natalie
/// (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
/// @author Minimal ERC1967 proxy by jtriley-eth (https://github.com/jtriley-eth/minimum-viable-proxy)
///
/// @dev Minimal proxy:
/// Although the sw0nt pattern saves 5 gas over the ERC1167 pattern during runtime,
/// it is not supported out-of-the-box on Etherscan. Hence, we choose to use the 0age pattern,
/// which saves 4 gas over the ERC1167 pattern during runtime, and has the smallest bytecode.
/// - Automatically verified on Etherscan.
///
/// @dev Minimal proxy (PUSH0 variant):
/// This is a new minimal proxy that uses the PUSH0 opcode introduced during Shanghai.
/// It is optimized first for minimal runtime gas, then for minimal bytecode.
/// The PUSH0 clone functions are intentionally postfixed with a jarring "_PUSH0" as
/// many EVM chains may not support the PUSH0 opcode in the early months after Shanghai.
/// Please use with caution.
/// - Automatically verified on Etherscan.
///
/// @dev Clones with immutable args (CWIA):
/// The implementation of CWIA here does NOT append the immutable args into the calldata
/// passed into delegatecall. It is simply an ERC1167 minimal proxy with the immutable arguments
/// appended to the back of the runtime bytecode.
/// - Uses the identity precompile (0x4) to copy args during deployment.
///
/// @dev Minimal ERC1967 proxy:
/// A minimal ERC1967 proxy, intended to be upgraded with UUPS.
/// This is NOT the same as ERC1967Factory's transparent proxy, which includes admin logic.
/// - Automatically verified on Etherscan.
///
/// @dev Minimal ERC1967 proxy with immutable args:
/// - Uses the identity precompile (0x4) to copy args during deployment.
/// - Automatically verified on Etherscan.
///
/// @dev ERC1967I proxy:
/// A variant of the minimal ERC1967 proxy, with a special code path that activates
/// if `calldatasize() == 1`. This code path skips the delegatecall and directly returns the
/// `implementation` address. The returned implementation is guaranteed to be valid if the
/// keccak256 of the proxy's code is equal to `ERC1967I_CODE_HASH`.
///
/// @dev ERC1967I proxy with immutable args:
/// A variant of the minimal ERC1967 proxy, with a special code path that activates
/// if `calldatasize() == 1`. This code path skips the delegatecall and directly returns the
/// - Uses the identity precompile (0x4) to copy args during deployment.
///
/// @dev Minimal ERC1967 beacon proxy:
/// A minimal beacon proxy, intended to be upgraded with an upgradable beacon.
/// - Automatically verified on Etherscan.
///
/// @dev Minimal ERC1967 beacon proxy with immutable args:
/// - Uses the identity precompile (0x4) to copy args during deployment.
/// - Automatically verified on Etherscan.
///
/// @dev ERC1967I beacon proxy:
/// A variant of the minimal ERC1967 beacon proxy, with a special code path that activates
/// if `calldatasize() == 1`. This code path skips the delegatecall and directly returns the
/// `implementation` address. The returned implementation is guaranteed to be valid if the
/// keccak256 of the proxy's code is equal to `ERC1967I_CODE_HASH`.
///
/// @dev ERC1967I proxy with immutable args:
/// A variant of the minimal ERC1967 beacon proxy, with a special code path that activates
/// if `calldatasize() == 1`. This code path skips the delegatecall and directly returns the
/// - Uses the identity precompile (0x4) to copy args during deployment.
library LibClone {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The keccak256 of deployed code for the clone proxy,
    /// with the implementation set to `address(0)`.
    bytes32 internal constant CLONE_CODE_HASH = 0x48db2cfdb2853fce0b464f1f93a1996469459df3ab6c812106074c4106a1eb1f;

    /// @dev The keccak256 of deployed code for the PUSH0 proxy,
    /// with the implementation set to `address(0)`.
    bytes32 internal constant PUSH0_CLONE_CODE_HASH =
        0x67bc6bde1b84d66e267c718ba44cf3928a615d29885537955cb43d44b3e789dc;

    /// @dev The keccak256 of deployed code for the ERC-1167 CWIA proxy,
    /// with the implementation set to `address(0)`.
    bytes32 internal constant CWIA_CODE_HASH = 0x3cf92464268225a4513da40a34d967354684c32cd0edd67b5f668dfe3550e940;

    /// @dev The keccak256 of the deployed code for the ERC1967 proxy.
    bytes32 internal constant ERC1967_CODE_HASH = 0xaaa52c8cc8a0e3fd27ce756cc6b4e70c51423e9b597b11f32d3e49f8b1fc890d;

    /// @dev The keccak256 of the deployed code for the ERC1967I proxy.
    bytes32 internal constant ERC1967I_CODE_HASH = 0xce700223c0d4cea4583409accfc45adac4a093b3519998a9cbbe1504dadba6f7;

    /// @dev The keccak256 of the deployed code for the ERC1967 beacon proxy.
    bytes32 internal constant ERC1967_BEACON_PROXY_CODE_HASH =
        0x14044459af17bc4f0f5aa2f658cb692add77d1302c29fe2aebab005eea9d1162;

    /// @dev The keccak256 of the deployed code for the ERC1967 beacon proxy.
    bytes32 internal constant ERC1967I_BEACON_PROXY_CODE_HASH =
        0xf8c46d2793d5aa984eb827aeaba4b63aedcab80119212fce827309788735519a;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the clone.
    error DeploymentFailed();

    /// @dev The salt must start with either the zero address or `by`.
    error SaltDoesNotStartWith();

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  MINIMAL PROXY OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a clone of `implementation`.
    function clone(address implementation) internal returns (address instance) {
        instance = clone(0, implementation);
    }

    /// @dev Deploys a clone of `implementation`.
    /// Deposits `value` ETH during deployment.
    function clone(uint256 value, address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * --------------------------------------------------------------------------+
             * CREATION (9 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                       |
             * --------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize     | r         |                              |
             * 3d         | RETURNDATASIZE    | 0 r       |                              |
             * 81         | DUP2              | r 0 r     |                              |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                              |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                              |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code   |
             * f3         | RETURN            |           | [0..runSize): runtime code   |
             * --------------------------------------------------------------------------|
             * RUNTIME (44 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode  | Mnemonic       | Stack                  | Memory                |
             * --------------------------------------------------------------------------|
             *                                                                           |
             * ::: keep some values in stack ::::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | 0                      |                       |
             * 3d      | RETURNDATASIZE | 0 0                    |                       |
             * 3d      | RETURNDATASIZE | 0 0 0                  |                       |
             * 3d      | RETURNDATASIZE | 0 0 0 0                |                       |
             *                                                                           |
             * ::: copy calldata to memory ::::::::::::::::::::::::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0 0 0            |                       |
             * 3d      | RETURNDATASIZE | 0 cds 0 0 0 0          |                       |
             * 3d      | RETURNDATASIZE | 0 0 cds 0 0 0 0        |                       |
             * 37      | CALLDATACOPY   | 0 0 0 0                | [0..cds): calldata    |
             *                                                                           |
             * ::: delegate call to the implementation contract :::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0 0 0            | [0..cds): calldata    |
             * 3d      | RETURNDATASIZE | 0 cds 0 0 0 0          | [0..cds): calldata    |
             * 73 addr | PUSH20 addr    | addr 0 cds 0 0 0 0     | [0..cds): calldata    |
             * 5a      | GAS            | gas addr 0 cds 0 0 0 0 | [0..cds): calldata    |
             * f4      | DELEGATECALL   | success 0 0            | [0..cds): calldata    |
             *                                                                           |
             * ::: copy return data to memory :::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds success 0 0        | [0..cds): calldata    |
             * 3d      | RETURNDATASIZE | rds rds success 0 0    | [0..cds): calldata    |
             * 93      | SWAP4          | 0 rds success 0 rds    | [0..cds): calldata    |
             * 80      | DUP1           | 0 0 rds success 0 rds  | [0..cds): calldata    |
             * 3e      | RETURNDATACOPY | success 0 rds          | [0..rds): returndata  |
             *                                                                           |
             * 60 0x2a | PUSH1 0x2a     | 0x2a success 0 rds     | [0..rds): returndata  |
             * 57      | JUMPI          | 0 rds                  | [0..rds): returndata  |
             *                                                                           |
             * ::: revert :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd      | REVERT         |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: return :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b      | JUMPDEST       | 0 rds                  | [0..rds): returndata  |
             * f3      | RETURN         |                        | [0..rds): returndata  |
             * --------------------------------------------------------------------------+
             */
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            instance := create(value, 0x0c, 0x35)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x21, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Deploys a deterministic clone of `implementation` with `salt`.
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        instance = cloneDeterministic(0, implementation, salt);
    }

    /// @dev Deploys a deterministic clone of `implementation` with `salt`.
    /// Deposits `value` ETH during deployment.
    function cloneDeterministic(
        uint256 value,
        address implementation,
        bytes32 salt
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            instance := create2(value, 0x0c, 0x35, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x21, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the initialization code of the clone of `implementation`.
    function initCode(address implementation) internal pure returns (bytes memory c) {
        /// @solidity memory-safe-assembly
        assembly {
            c := mload(0x40)
            mstore(add(c, 0x40), 0x5af43d3d93803e602a57fd5bf30000000000000000000000)
            mstore(add(c, 0x28), implementation)
            mstore(add(c, 0x14), 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            mstore(c, 0x35) // Store the length.
            mstore(0x40, add(c, 0x60)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`.
    function initCodeHash(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            hash := keccak256(0x0c, 0x35)
            mstore(0x21, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the address of the clone of `implementation`, with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHash(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          MINIMAL PROXY OPERATIONS (PUSH0 VARIANT)          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a PUSH0 clone of `implementation`.
    function clone_PUSH0(address implementation) internal returns (address instance) {
        instance = clone_PUSH0(0, implementation);
    }

    /// @dev Deploys a PUSH0 clone of `implementation`.
    /// Deposits `value` ETH during deployment.
    function clone_PUSH0(uint256 value, address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * --------------------------------------------------------------------------+
             * CREATION (9 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                       |
             * --------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize     | r         |                              |
             * 5f         | PUSH0             | 0 r       |                              |
             * 81         | DUP2              | r 0 r     |                              |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                              |
             * 5f         | PUSH0             | 0 o r 0 r |                              |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code   |
             * f3         | RETURN            |           | [0..runSize): runtime code   |
             * --------------------------------------------------------------------------|
             * RUNTIME (45 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode  | Mnemonic       | Stack                  | Memory                |
             * --------------------------------------------------------------------------|
             *                                                                           |
             * ::: keep some values in stack ::::::::::::::::::::::::::::::::::::::::::: |
             * 5f      | PUSH0          | 0                      |                       |
             * 5f      | PUSH0          | 0 0                    |                       |
             *                                                                           |
             * ::: copy calldata to memory ::::::::::::::::::::::::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0                |                       |
             * 5f      | PUSH0          | 0 cds 0 0              |                       |
             * 5f      | PUSH0          | 0 0 cds 0 0            |                       |
             * 37      | CALLDATACOPY   | 0 0                    | [0..cds): calldata    |
             *                                                                           |
             * ::: delegate call to the implementation contract :::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0                | [0..cds): calldata    |
             * 5f      | PUSH0          | 0 cds 0 0              | [0..cds): calldata    |
             * 73 addr | PUSH20 addr    | addr 0 cds 0 0         | [0..cds): calldata    |
             * 5a      | GAS            | gas addr 0 cds 0 0     | [0..cds): calldata    |
             * f4      | DELEGATECALL   | success                | [0..cds): calldata    |
             *                                                                           |
             * ::: copy return data to memory :::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds success            | [0..cds): calldata    |
             * 5f      | PUSH0          | 0 rds success          | [0..cds): calldata    |
             * 5f      | PUSH0          | 0 0 rds success        | [0..cds): calldata    |
             * 3e      | RETURNDATACOPY | success                | [0..rds): returndata  |
             *                                                                           |
             * 60 0x29 | PUSH1 0x29     | 0x29 success           | [0..rds): returndata  |
             * 57      | JUMPI          |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: revert :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds                    | [0..rds): returndata  |
             * 5f      | PUSH0          | 0 rds                  | [0..rds): returndata  |
             * fd      | REVERT         |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: return :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b      | JUMPDEST       |                        | [0..rds): returndata  |
             * 3d      | RETURNDATASIZE | rds                    | [0..rds): returndata  |
             * 5f      | PUSH0          | 0 rds                  | [0..rds): returndata  |
             * f3      | RETURN         |                        | [0..rds): returndata  |
             * --------------------------------------------------------------------------+
             */
            mstore(0x24, 0x5af43d5f5f3e6029573d5ffd5b3d5ff3) // 16
            mstore(0x14, implementation) // 20
            mstore(0x00, 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            instance := create(value, 0x0e, 0x36)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x24, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Deploys a deterministic PUSH0 clone of `implementation` with `salt`.
    function cloneDeterministic_PUSH0(address implementation, bytes32 salt) internal returns (address instance) {
        instance = cloneDeterministic_PUSH0(0, implementation, salt);
    }

    /// @dev Deploys a deterministic PUSH0 clone of `implementation` with `salt`.
    /// Deposits `value` ETH during deployment.
    function cloneDeterministic_PUSH0(
        uint256 value,
        address implementation,
        bytes32 salt
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x24, 0x5af43d5f5f3e6029573d5ffd5b3d5ff3) // 16
            mstore(0x14, implementation) // 20
            mstore(0x00, 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            instance := create2(value, 0x0e, 0x36, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x24, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the initialization code of the PUSH0 clone of `implementation`.
    function initCode_PUSH0(address implementation) internal pure returns (bytes memory c) {
        /// @solidity memory-safe-assembly
        assembly {
            c := mload(0x40)
            mstore(add(c, 0x40), 0x5af43d5f5f3e6029573d5ffd5b3d5ff300000000000000000000) // 16
            mstore(add(c, 0x26), implementation) // 20
            mstore(add(c, 0x12), 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            mstore(c, 0x36) // Store the length.
            mstore(0x40, add(c, 0x60)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the PUSH0 clone of `implementation`.
    function initCodeHash_PUSH0(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x24, 0x5af43d5f5f3e6029573d5ffd5b3d5ff3) // 16
            mstore(0x14, implementation) // 20
            mstore(0x00, 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            hash := keccak256(0x0e, 0x36)
            mstore(0x24, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the address of the PUSH0 clone of `implementation`, with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress_PUSH0(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHash_PUSH0(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           CLONES WITH IMMUTABLE ARGS OPERATIONS            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a clone of `implementation` with immutable arguments encoded in `args`.
    function clone(address implementation, bytes memory args) internal returns (address instance) {
        instance = clone(0, implementation, args);
    }

    /// @dev Deploys a clone of `implementation` with immutable arguments encoded in `args`.
    /// Deposits `value` ETH during deployment.
    function clone(uint256 value, address implementation, bytes memory args) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * ---------------------------------------------------------------------------+
             * CREATION (10 bytes)                                                        |
             * ---------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                        |
             * ---------------------------------------------------------------------------|
             * 61 runSize | PUSH2 runSize     | r         |                               |
             * 3d         | RETURNDATASIZE    | 0 r       |                               |
             * 81         | DUP2              | r 0 r     |                               |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                               |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                               |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code    |
             * f3         | RETURN            |           | [0..runSize): runtime code    |
             * ---------------------------------------------------------------------------|
             * RUNTIME (45 bytes + extraLength)                                           |
             * ---------------------------------------------------------------------------|
             * Opcode   | Mnemonic       | Stack                  | Memory                |
             * ---------------------------------------------------------------------------|
             *                                                                            |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds                    |                       |
             * 3d       | RETURNDATASIZE | 0 cds                  |                       |
             * 3d       | RETURNDATASIZE | 0 0 cds                |                       |
             * 37       | CALLDATACOPY   |                        | [0..cds): calldata    |
             *                                                                            |
             * ::: delegate call to the implementation contract ::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | 0                      | [0..cds): calldata    |
             * 3d       | RETURNDATASIZE | 0 0                    | [0..cds): calldata    |
             * 3d       | RETURNDATASIZE | 0 0 0                  | [0..cds): calldata    |
             * 36       | CALLDATASIZE   | cds 0 0 0              | [0..cds): calldata    |
             * 3d       | RETURNDATASIZE | 0 cds 0 0 0 0          | [0..cds): calldata    |
             * 73 addr  | PUSH20 addr    | addr 0 cds 0 0 0 0     | [0..cds): calldata    |
             * 5a       | GAS            | gas addr 0 cds 0 0 0 0 | [0..cds): calldata    |
             * f4       | DELEGATECALL   | success 0 0            | [0..cds): calldata    |
             *                                                                            |
             * ::: copy return data to memory ::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | rds success 0          | [0..cds): calldata    |
             * 82       | DUP3           | 0 rds success 0         | [0..cds): calldata   |
             * 80       | DUP1           | 0 0 rds success 0      | [0..cds): calldata    |
             * 3e       | RETURNDATACOPY | success 0              | [0..rds): returndata  |
             * 90       | SWAP1          | 0 success              | [0..rds): returndata  |
             * 3d       | RETURNDATASIZE | rds 0 success          | [0..rds): returndata  |
             * 91       | SWAP2          | success 0 rds          | [0..rds): returndata  |
             *                                                                            |
             * 60 0x2b  | PUSH1 0x2b     | 0x2b success 0 rds     | [0..rds): returndata  |
             * 57       | JUMPI          | 0 rds                  | [0..rds): returndata  |
             *                                                                            |
             * ::: revert ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd       | REVERT         |                        | [0..rds): returndata  |
             *                                                                            |
             * ::: return ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b       | JUMPDEST       | 0 rds                  | [0..rds): returndata  |
             * f3       | RETURN         |                        | [0..rds): returndata  |
             * ---------------------------------------------------------------------------+
             */
            let m := mload(0x40)
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x43), n))
            mstore(add(m, 0x23), 0x5af43d82803e903d91602b57fd5bf3)
            mstore(add(m, 0x14), implementation)
            mstore(m, add(0xfe61002d3d81600a3d39f3363d3d373d3d3d363d73, shl(136, n)))
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x2d = 0xffd2`.
            instance := create(value, add(m, add(0x0b, lt(n, 0xffd3))), add(n, 0x37))
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Deploys a deterministic clone of `implementation`
    /// with immutable arguments encoded in `args` and `salt`.
    function cloneDeterministic(
        address implementation,
        bytes memory args,
        bytes32 salt
    ) internal returns (address instance) {
        instance = cloneDeterministic(0, implementation, args, salt);
    }

    /// @dev Deploys a deterministic clone of `implementation`
    /// with immutable arguments encoded in `args` and `salt`.
    function cloneDeterministic(
        uint256 value,
        address implementation,
        bytes memory args,
        bytes32 salt
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x43), n))
            mstore(add(m, 0x23), 0x5af43d82803e903d91602b57fd5bf3)
            mstore(add(m, 0x14), implementation)
            mstore(m, add(0xfe61002d3d81600a3d39f3363d3d373d3d3d363d73, shl(136, n)))
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x2d = 0xffd2`.
            instance := create2(value, add(m, add(0x0b, lt(n, 0xffd3))), add(n, 0x37), salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Deploys a deterministic clone of `implementation`
    /// with immutable arguments encoded in `args` and `salt`.
    /// This method does not revert if the clone has already been deployed.
    function createDeterministicClone(
        address implementation,
        bytes memory args,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        return createDeterministicClone(0, implementation, args, salt);
    }

    /// @dev Deploys a deterministic clone of `implementation`
    /// with immutable arguments encoded in `args` and `salt`.
    /// This method does not revert if the clone has already been deployed.
    function createDeterministicClone(
        uint256 value,
        address implementation,
        bytes memory args,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x43), n))
            mstore(add(m, 0x23), 0x5af43d82803e903d91602b57fd5bf3)
            mstore(add(m, 0x14), implementation)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x2d = 0xffd2`.
            // forgefmt: disable-next-item
            mstore(add(m, gt(n, 0xffd2)), add(0xfe61002d3d81600a3d39f3363d3d373d3d3d363d73, shl(136, n)))
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, keccak256(add(m, 0x0c), add(n, 0x37)))
            mstore(0x01, shl(96, address()))
            mstore(0x15, salt)
            instance := keccak256(0x00, 0x55)
            for {

            } 1 {

            } {
                if iszero(extcodesize(instance)) {
                    instance := create2(value, add(m, 0x0c), add(n, 0x37), salt)
                    if iszero(instance) {
                        mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                        revert(0x1c, 0x04)
                    }
                    break
                }
                alreadyDeployed := 1
                if iszero(value) {
                    break
                }
                if iszero(call(gas(), instance, value, codesize(), 0x00, codesize(), 0x00)) {
                    mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                    revert(0x1c, 0x04)
                }
                break
            }
            mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the initialization code of the clone of `implementation`
    /// using immutable arguments encoded in `args`.
    function initCode(address implementation, bytes memory args) internal pure returns (bytes memory c) {
        /// @solidity memory-safe-assembly
        assembly {
            c := mload(0x40)
            let n := mload(args)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x2d = 0xffd2`.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0xffd2))
            for {
                let i := 0
            } lt(i, n) {
                i := add(i, 0x20)
            } {
                mstore(add(add(c, 0x57), i), mload(add(add(args, 0x20), i)))
            }
            mstore(add(c, 0x37), 0x5af43d82803e903d91602b57fd5bf3)
            mstore(add(c, 0x28), implementation)
            mstore(add(c, 0x14), add(0x61002d3d81600a3d39f3363d3d373d3d3d363d73, shl(136, n)))
            mstore(c, add(0x37, n)) // Store the length.
            mstore(add(c, add(n, 0x57)), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(c, add(n, 0x77))) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`
    /// using immutable arguments encoded in `args`.
    function initCodeHash(address implementation, bytes memory args) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x2d = 0xffd2`.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0xffd2))
            for {
                let i := 0
            } lt(i, n) {
                i := add(i, 0x20)
            } {
                mstore(add(add(m, 0x43), i), mload(add(add(args, 0x20), i)))
            }
            mstore(add(m, 0x23), 0x5af43d82803e903d91602b57fd5bf3)
            mstore(add(m, 0x14), implementation)
            mstore(m, add(0x61002d3d81600a3d39f3363d3d373d3d3d363d73, shl(136, n)))
            hash := keccak256(add(m, 0x0c), add(n, 0x37))
        }
    }

    /// @dev Returns the address of the clone of
    /// `implementation` using immutable arguments encoded in `args`, with `salt`, by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(
        address implementation,
        bytes memory data,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHash(implementation, data);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /// @dev Equivalent to `argsOnClone(instance, 0, 2 ** 256 - 1)`.
    function argsOnClone(address instance) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            mstore(args, and(0xffffffffff, sub(extcodesize(instance), 0x2d))) // Store the length.
            extcodecopy(instance, add(args, 0x20), 0x2d, add(mload(args), 0x20))
            mstore(0x40, add(mload(args), add(args, 0x40))) // Allocate memory.
        }
    }

    /// @dev Equivalent to `argsOnClone(instance, start, 2 ** 256 - 1)`.
    function argsOnClone(address instance, uint256 start) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            let n := and(0xffffffffff, sub(extcodesize(instance), 0x2d))
            let l := sub(n, and(0xffffff, mul(lt(start, n), start)))
            extcodecopy(instance, args, add(start, 0x0d), add(l, 0x40))
            mstore(args, mul(sub(n, start), lt(start, n))) // Store the length.
            mstore(0x40, add(args, add(0x40, mload(args)))) // Allocate memory.
        }
    }

    /// @dev Returns a slice of the immutable arguments on `instance` from `start` to `end`.
    /// `start` and `end` will be clamped to the range `[0, args.length]`.
    /// The `instance` MUST be deployed via the clone with immutable args functions.
    /// Otherwise, the behavior is undefined.
    /// Out-of-gas reverts if `instance` does not have any code.
    function argsOnClone(address instance, uint256 start, uint256 end) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            if iszero(lt(end, 0xffff)) {
                end := 0xffff
            }
            let d := mul(sub(end, start), lt(start, end))
            extcodecopy(instance, args, add(start, 0x0d), add(d, 0x20))
            if iszero(and(0xff, mload(add(args, d)))) {
                let n := sub(extcodesize(instance), 0x2d)
                returndatacopy(returndatasize(), returndatasize(), shr(40, n))
                d := mul(gt(n, start), sub(d, mul(gt(end, n), sub(end, n))))
            }
            mstore(args, d) // Store the length.
            mstore(add(add(args, 0x20), d), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(add(args, 0x40), d)) // Allocate memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              MINIMAL ERC1967 PROXY OPERATIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note: The ERC1967 proxy here is intended to be upgraded with UUPS.
    // This is NOT the same as ERC1967Factory's transparent proxy, which includes admin logic.

    /// @dev Deploys a minimal ERC1967 proxy with `implementation`.
    function deployERC1967(address implementation) internal returns (address instance) {
        instance = deployERC1967(0, implementation);
    }

    /// @dev Deploys a minimal ERC1967 proxy with `implementation`.
    /// Deposits `value` ETH during deployment.
    function deployERC1967(uint256 value, address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * ---------------------------------------------------------------------------------+
             * CREATION (34 bytes)                                                              |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize  | r                |                                 |
             * 3d         | RETURNDATASIZE | 0 r              |                                 |
             * 81         | DUP2           | r 0 r            |                                 |
             * 60 offset  | PUSH1 offset   | o r 0 r          |                                 |
             * 3d         | RETURNDATASIZE | 0 o r 0 r        |                                 |
             * 39         | CODECOPY       | 0 r              | [0..runSize): runtime code      |
             * 73 impl    | PUSH20 impl    | impl 0 r         | [0..runSize): runtime code      |
             * 60 slotPos | PUSH1 slotPos  | slotPos impl 0 r | [0..runSize): runtime code      |
             * 51         | MLOAD          | slot impl 0 r    | [0..runSize): runtime code      |
             * 55         | SSTORE         | 0 r              | [0..runSize): runtime code      |
             * f3         | RETURN         |                  | [0..runSize): runtime code      |
             * ---------------------------------------------------------------------------------|
             * RUNTIME (61 bytes)                                                               |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             *                                                                                  |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36         | CALLDATASIZE   | cds              |                                 |
             * 3d         | RETURNDATASIZE | 0 cds            |                                 |
             * 3d         | RETURNDATASIZE | 0 0 cds          |                                 |
             * 37         | CALLDATACOPY   |                  | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: delegatecall to implementation ::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | 0                |                                 |
             * 3d         | RETURNDATASIZE | 0 0              |                                 |
             * 36         | CALLDATASIZE   | cds 0 0          | [0..calldatasize): calldata     |
             * 3d         | RETURNDATASIZE | 0 cds 0 0        | [0..calldatasize): calldata     |
             * 7f slot    | PUSH32 slot    | s 0 cds 0 0      | [0..calldatasize): calldata     |
             * 54         | SLOAD          | i 0 cds 0 0      | [0..calldatasize): calldata     |
             * 5a         | GAS            | g i 0 cds 0 0    | [0..calldatasize): calldata     |
             * f4         | DELEGATECALL   | succ             | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: copy returndata to memory :::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds succ         | [0..calldatasize): calldata     |
             * 60 0x00    | PUSH1 0x00     | 0 rds succ       | [0..calldatasize): calldata     |
             * 80         | DUP1           | 0 0 rds succ     | [0..calldatasize): calldata     |
             * 3e         | RETURNDATACOPY | succ             | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: branch on delegatecall status :::::::::::::::::::::::::::::::::::::::::::::: |
             * 60 0x38    | PUSH1 0x38     | dest succ        | [0..returndatasize): returndata |
             * 57         | JUMPI          |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall failed, revert :::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds              | [0..returndatasize): returndata |
             * 60 0x00    | PUSH1 0x00     | 0 rds            | [0..returndatasize): returndata |
             * fd         | REVERT         |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall succeeded, return ::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b         | JUMPDEST       |                  | [0..returndatasize): returndata |
             * 3d         | RETURNDATASIZE | rds              | [0..returndatasize): returndata |
             * 60 0x00    | PUSH1 0x00     | 0 rds            | [0..returndatasize): returndata |
             * f3         | RETURN         |                  | [0..returndatasize): returndata |
             * ---------------------------------------------------------------------------------+
             */
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            instance := create(value, 0x21, 0x5f)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Deploys a deterministic minimal ERC1967 proxy with `implementation` and `salt`.
    function deployDeterministicERC1967(address implementation, bytes32 salt) internal returns (address instance) {
        instance = deployDeterministicERC1967(0, implementation, salt);
    }

    /// @dev Deploys a deterministic minimal ERC1967 proxy with `implementation` and `salt`.
    /// Deposits `value` ETH during deployment.
    function deployDeterministicERC1967(
        uint256 value,
        address implementation,
        bytes32 salt
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            instance := create2(value, 0x21, 0x5f, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Creates a deterministic minimal ERC1967 proxy with `implementation` and `salt`.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967(
        address implementation,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        return createDeterministicERC1967(0, implementation, salt);
    }

    /// @dev Creates a deterministic minimal ERC1967 proxy with `implementation` and `salt`.
    /// Deposits `value` ETH during deployment.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967(
        uint256 value,
        address implementation,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            // Compute and store the bytecode hash.
            mstore(add(m, 0x35), keccak256(0x21, 0x5f))
            mstore(m, shl(88, address()))
            mstore8(m, 0xff) // Write the prefix.
            mstore(add(m, 0x15), salt)
            instance := keccak256(m, 0x55)
            for {

            } 1 {

            } {
                if iszero(extcodesize(instance)) {
                    instance := create2(value, 0x21, 0x5f, salt)
                    if iszero(instance) {
                        mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                        revert(0x1c, 0x04)
                    }
                    break
                }
                alreadyDeployed := 1
                if iszero(value) {
                    break
                }
                if iszero(call(gas(), instance, value, codesize(), 0x00, codesize(), 0x00)) {
                    mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                    revert(0x1c, 0x04)
                }
                break
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the initialization code of the minimal ERC1967 proxy of `implementation`.
    function initCodeERC1967(address implementation) internal pure returns (bytes memory c) {
        /// @solidity memory-safe-assembly
        assembly {
            c := mload(0x40)
            mstore(add(c, 0x60), 0x3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f300)
            mstore(add(c, 0x40), 0x55f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc)
            mstore(add(c, 0x20), or(shl(24, implementation), 0x600951))
            mstore(add(c, 0x09), 0x603d3d8160223d3973)
            mstore(c, 0x5f) // Store the length.
            mstore(0x40, add(c, 0x80)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the minimal ERC1967 proxy of `implementation`.
    function initCodeHashERC1967(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            hash := keccak256(0x21, 0x5f)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the address of the ERC1967 proxy of `implementation`, with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddressERC1967(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHashERC1967(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*    MINIMAL ERC1967 PROXY WITH IMMUTABLE ARGS OPERATIONS    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a minimal ERC1967 proxy with `implementation` and `args`.
    function deployERC1967(address implementation, bytes memory args) internal returns (address instance) {
        instance = deployERC1967(0, implementation, args);
    }

    /// @dev Deploys a minimal ERC1967 proxy with `implementation` and `args`.
    /// Deposits `value` ETH during deployment.
    function deployERC1967(
        uint256 value,
        address implementation,
        bytes memory args
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x60), n))
            mstore(add(m, 0x40), 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(add(m, 0x20), 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x16, 0x6009)
            mstore(0x14, implementation)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x3d = 0xffc2`.
            mstore(gt(n, 0xffc2), add(0xfe61003d3d8160233d3973, shl(56, n)))
            mstore(m, mload(0x16))
            instance := create(value, m, add(n, 0x60))
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Deploys a deterministic minimal ERC1967 proxy with `implementation`, `args` and `salt`.
    function deployDeterministicERC1967(
        address implementation,
        bytes memory args,
        bytes32 salt
    ) internal returns (address instance) {
        instance = deployDeterministicERC1967(0, implementation, args, salt);
    }

    /// @dev Deploys a deterministic minimal ERC1967 proxy with `implementation`, `args` and `salt`.
    /// Deposits `value` ETH during deployment.
    function deployDeterministicERC1967(
        uint256 value,
        address implementation,
        bytes memory args,
        bytes32 salt
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x60), n))
            mstore(add(m, 0x40), 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(add(m, 0x20), 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x16, 0x6009)
            mstore(0x14, implementation)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x3d = 0xffc2`.
            mstore(gt(n, 0xffc2), add(0xfe61003d3d8160233d3973, shl(56, n)))
            mstore(m, mload(0x16))
            instance := create2(value, m, add(n, 0x60), salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Creates a deterministic minimal ERC1967 proxy with `implementation`, `args` and `salt`.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967(
        address implementation,
        bytes memory args,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        return createDeterministicERC1967(0, implementation, args, salt);
    }

    /// @dev Creates a deterministic minimal ERC1967 proxy with `implementation`, `args` and `salt`.
    /// Deposits `value` ETH during deployment.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967(
        uint256 value,
        address implementation,
        bytes memory args,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x60), n))
            mstore(add(m, 0x40), 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(add(m, 0x20), 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x16, 0x6009)
            mstore(0x14, implementation)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x3d = 0xffc2`.
            mstore(gt(n, 0xffc2), add(0xfe61003d3d8160233d3973, shl(56, n)))
            mstore(m, mload(0x16))
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, keccak256(m, add(n, 0x60)))
            mstore(0x01, shl(96, address()))
            mstore(0x15, salt)
            instance := keccak256(0x00, 0x55)
            for {

            } 1 {

            } {
                if iszero(extcodesize(instance)) {
                    instance := create2(value, m, add(n, 0x60), salt)
                    if iszero(instance) {
                        mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                        revert(0x1c, 0x04)
                    }
                    break
                }
                alreadyDeployed := 1
                if iszero(value) {
                    break
                }
                if iszero(call(gas(), instance, value, codesize(), 0x00, codesize(), 0x00)) {
                    mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                    revert(0x1c, 0x04)
                }
                break
            }
            mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the initialization code of the minimal ERC1967 proxy of `implementation` and `args`.
    function initCodeERC1967(address implementation, bytes memory args) internal pure returns (bytes memory c) {
        /// @solidity memory-safe-assembly
        assembly {
            c := mload(0x40)
            let n := mload(args)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x3d = 0xffc2`.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0xffc2))
            for {
                let i := 0
            } lt(i, n) {
                i := add(i, 0x20)
            } {
                mstore(add(add(c, 0x80), i), mload(add(add(args, 0x20), i)))
            }
            mstore(add(c, 0x60), 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(add(c, 0x40), 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(add(c, 0x20), 0x6009)
            mstore(add(c, 0x1e), implementation)
            mstore(add(c, 0x0a), add(0x61003d3d8160233d3973, shl(56, n)))
            mstore(c, add(n, 0x60)) // Store the length.
            mstore(add(c, add(n, 0x80)), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(c, add(n, 0xa0))) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the minimal ERC1967 proxy of `implementation` and `args`.
    function initCodeHashERC1967(address implementation, bytes memory args) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x3d = 0xffc2`.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0xffc2))
            for {
                let i := 0
            } lt(i, n) {
                i := add(i, 0x20)
            } {
                mstore(add(add(m, 0x60), i), mload(add(add(args, 0x20), i)))
            }
            mstore(add(m, 0x40), 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(add(m, 0x20), 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x16, 0x6009)
            mstore(0x14, implementation)
            mstore(0x00, add(0x61003d3d8160233d3973, shl(56, n)))
            mstore(m, mload(0x16))
            hash := keccak256(m, add(n, 0x60))
        }
    }

    /// @dev Returns the address of the ERC1967 proxy of `implementation`, `args`, with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddressERC1967(
        address implementation,
        bytes memory args,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHashERC1967(implementation, args);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /// @dev Equivalent to `argsOnERC1967(instance, start, 2 ** 256 - 1)`.
    function argsOnERC1967(address instance) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            mstore(args, and(0xffffffffff, sub(extcodesize(instance), 0x3d))) // Store the length.
            extcodecopy(instance, add(args, 0x20), 0x3d, add(mload(args), 0x20))
            mstore(0x40, add(mload(args), add(args, 0x40))) // Allocate memory.
        }
    }

    /// @dev Equivalent to `argsOnERC1967(instance, start, 2 ** 256 - 1)`.
    function argsOnERC1967(address instance, uint256 start) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            let n := and(0xffffffffff, sub(extcodesize(instance), 0x3d))
            let l := sub(n, and(0xffffff, mul(lt(start, n), start)))
            extcodecopy(instance, args, add(start, 0x1d), add(l, 0x40))
            mstore(args, mul(sub(n, start), lt(start, n))) // Store the length.
            mstore(0x40, add(args, add(0x40, mload(args)))) // Allocate memory.
        }
    }

    /// @dev Returns a slice of the immutable arguments on `instance` from `start` to `end`.
    /// `start` and `end` will be clamped to the range `[0, args.length]`.
    /// The `instance` MUST be deployed via the ERC1967 with immutable args functions.
    /// Otherwise, the behavior is undefined.
    /// Out-of-gas reverts if `instance` does not have any code.
    function argsOnERC1967(address instance, uint256 start, uint256 end) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            if iszero(lt(end, 0xffff)) {
                end := 0xffff
            }
            let d := mul(sub(end, start), lt(start, end))
            extcodecopy(instance, args, add(start, 0x1d), add(d, 0x20))
            if iszero(and(0xff, mload(add(args, d)))) {
                let n := sub(extcodesize(instance), 0x3d)
                returndatacopy(returndatasize(), returndatasize(), shr(40, n))
                d := mul(gt(n, start), sub(d, mul(gt(end, n), sub(end, n))))
            }
            mstore(args, d) // Store the length.
            mstore(add(add(args, 0x20), d), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(add(args, 0x40), d)) // Allocate memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 ERC1967I PROXY OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note: This proxy has a special code path that activates if `calldatasize() == 1`.
    // This code path skips the delegatecall and directly returns the `implementation` address.
    // The returned implementation is guaranteed to be valid if the keccak256 of the
    // proxy's code is equal to `ERC1967I_CODE_HASH`.

    /// @dev Deploys a ERC1967I proxy with `implementation`.
    function deployERC1967I(address implementation) internal returns (address instance) {
        instance = deployERC1967I(0, implementation);
    }

    /// @dev Deploys a ERC1967I proxy with `implementation`.
    /// Deposits `value` ETH during deployment.
    function deployERC1967I(uint256 value, address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * ---------------------------------------------------------------------------------+
             * CREATION (34 bytes)                                                              |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize  | r                |                                 |
             * 3d         | RETURNDATASIZE | 0 r              |                                 |
             * 81         | DUP2           | r 0 r            |                                 |
             * 60 offset  | PUSH1 offset   | o r 0 r          |                                 |
             * 3d         | RETURNDATASIZE | 0 o r 0 r        |                                 |
             * 39         | CODECOPY       | 0 r              | [0..runSize): runtime code      |
             * 73 impl    | PUSH20 impl    | impl 0 r         | [0..runSize): runtime code      |
             * 60 slotPos | PUSH1 slotPos  | slotPos impl 0 r | [0..runSize): runtime code      |
             * 51         | MLOAD          | slot impl 0 r    | [0..runSize): runtime code      |
             * 55         | SSTORE         | 0 r              | [0..runSize): runtime code      |
             * f3         | RETURN         |                  | [0..runSize): runtime code      |
             * ---------------------------------------------------------------------------------|
             * RUNTIME (82 bytes)                                                               |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             *                                                                                  |
             * ::: check calldatasize ::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36         | CALLDATASIZE   | cds              |                                 |
             * 58         | PC             | 1 cds            |                                 |
             * 14         | EQ             | eqs              |                                 |
             * 60 0x43    | PUSH1 0x43     | dest eqs         |                                 |
             * 57         | JUMPI          |                  |                                 |
             *                                                                                  |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36         | CALLDATASIZE   | cds              |                                 |
             * 3d         | RETURNDATASIZE | 0 cds            |                                 |
             * 3d         | RETURNDATASIZE | 0 0 cds          |                                 |
             * 37         | CALLDATACOPY   |                  | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: delegatecall to implementation ::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | 0                |                                 |
             * 3d         | RETURNDATASIZE | 0 0              |                                 |
             * 36         | CALLDATASIZE   | cds 0 0          | [0..calldatasize): calldata     |
             * 3d         | RETURNDATASIZE | 0 cds 0 0        | [0..calldatasize): calldata     |
             * 7f slot    | PUSH32 slot    | s 0 cds 0 0      | [0..calldatasize): calldata     |
             * 54         | SLOAD          | i 0 cds 0 0      | [0..calldatasize): calldata     |
             * 5a         | GAS            | g i 0 cds 0 0    | [0..calldatasize): calldata     |
             * f4         | DELEGATECALL   | succ             | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: copy returndata to memory :::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds succ         | [0..calldatasize): calldata     |
             * 60 0x00    | PUSH1 0x00     | 0 rds succ       | [0..calldatasize): calldata     |
             * 80         | DUP1           | 0 0 rds succ     | [0..calldatasize): calldata     |
             * 3e         | RETURNDATACOPY | succ             | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: branch on delegatecall status :::::::::::::::::::::::::::::::::::::::::::::: |
             * 60 0x3E    | PUSH1 0x3E     | dest succ        | [0..returndatasize): returndata |
             * 57         | JUMPI          |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall failed, revert :::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds              | [0..returndatasize): returndata |
             * 60 0x00    | PUSH1 0x00     | 0 rds            | [0..returndatasize): returndata |
             * fd         | REVERT         |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall succeeded, return ::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b         | JUMPDEST       |                  | [0..returndatasize): returndata |
             * 3d         | RETURNDATASIZE | rds              | [0..returndatasize): returndata |
             * 60 0x00    | PUSH1 0x00     | 0 rds            | [0..returndatasize): returndata |
             * f3         | RETURN         |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: implementation , return :::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b         | JUMPDEST       |                  |                                 |
             * 60 0x20    | PUSH1 0x20     | 32               |                                 |
             * 60 0x0F    | PUSH1 0x0F     | o 32             |                                 |
             * 3d         | RETURNDATASIZE | 0 o 32           |                                 |
             * 39         | CODECOPY       |                  | [0..32): implementation slot    |
             * 3d         | RETURNDATASIZE | 0                | [0..32): implementation slot    |
             * 51         | MLOAD          | slot             | [0..32): implementation slot    |
             * 54         | SLOAD          | impl             | [0..32): implementation slot    |
             * 3d         | RETURNDATASIZE | 0 impl           | [0..32): implementation slot    |
             * 52         | MSTORE         |                  | [0..32): implementation address |
             * 59         | MSIZE          | 32               | [0..32): implementation address |
             * 3d         | RETURNDATASIZE | 0 32             | [0..32): implementation address |
             * f3         | RETURN         |                  | [0..32): implementation address |
             * ---------------------------------------------------------------------------------+
             */
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3)
            mstore(0x40, 0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4)
            mstore(0x20, 0x600f5155f3365814604357363d3d373d3d363d7f360894)
            mstore(0x09, or(shl(160, 0x60523d8160223d3973), shr(96, shl(96, implementation))))
            instance := create(value, 0x0c, 0x74)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Deploys a deterministic ERC1967I proxy with `implementation` and `salt`.
    function deployDeterministicERC1967I(address implementation, bytes32 salt) internal returns (address instance) {
        instance = deployDeterministicERC1967I(0, implementation, salt);
    }

    /// @dev Deploys a deterministic ERC1967I proxy with `implementation` and `salt`.
    /// Deposits `value` ETH during deployment.
    function deployDeterministicERC1967I(
        uint256 value,
        address implementation,
        bytes32 salt
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3)
            mstore(0x40, 0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4)
            mstore(0x20, 0x600f5155f3365814604357363d3d373d3d363d7f360894)
            mstore(0x09, or(shl(160, 0x60523d8160223d3973), shr(96, shl(96, implementation))))
            instance := create2(value, 0x0c, 0x74, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Creates a deterministic ERC1967I proxy with `implementation` and `salt`.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967I(
        address implementation,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        return createDeterministicERC1967I(0, implementation, salt);
    }

    /// @dev Creates a deterministic ERC1967I proxy with `implementation` and `salt`.
    /// Deposits `value` ETH during deployment.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967I(
        uint256 value,
        address implementation,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3)
            mstore(0x40, 0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4)
            mstore(0x20, 0x600f5155f3365814604357363d3d373d3d363d7f360894)
            mstore(0x09, or(shl(160, 0x60523d8160223d3973), shr(96, shl(96, implementation))))
            // Compute and store the bytecode hash.
            mstore(add(m, 0x35), keccak256(0x0c, 0x74))
            mstore(m, shl(88, address()))
            mstore8(m, 0xff) // Write the prefix.
            mstore(add(m, 0x15), salt)
            instance := keccak256(m, 0x55)
            for {

            } 1 {

            } {
                if iszero(extcodesize(instance)) {
                    instance := create2(value, 0x0c, 0x74, salt)
                    if iszero(instance) {
                        mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                        revert(0x1c, 0x04)
                    }
                    break
                }
                alreadyDeployed := 1
                if iszero(value) {
                    break
                }
                if iszero(call(gas(), instance, value, codesize(), 0x00, codesize(), 0x00)) {
                    mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                    revert(0x1c, 0x04)
                }
                break
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the initialization code of the ERC1967I proxy of `implementation`.
    function initCodeERC1967I(address implementation) internal pure returns (bytes memory c) {
        /// @solidity memory-safe-assembly
        assembly {
            c := mload(0x40)
            mstore(add(c, 0x74), 0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3)
            mstore(add(c, 0x54), 0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4)
            mstore(add(c, 0x34), 0x600f5155f3365814604357363d3d373d3d363d7f360894)
            mstore(add(c, 0x1d), implementation)
            mstore(add(c, 0x09), 0x60523d8160223d3973)
            mstore(add(c, 0x94), 0)
            mstore(c, 0x74) // Store the length.
            mstore(0x40, add(c, 0xa0)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the ERC1967I proxy of `implementation`.
    function initCodeHashERC1967I(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3)
            mstore(0x40, 0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4)
            mstore(0x20, 0x600f5155f3365814604357363d3d373d3d363d7f360894)
            mstore(0x09, or(shl(160, 0x60523d8160223d3973), shr(96, shl(96, implementation))))
            hash := keccak256(0x0c, 0x74)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the address of the ERC1967I proxy of `implementation`, with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddressERC1967I(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHashERC1967I(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*       ERC1967I PROXY WITH IMMUTABLE ARGS OPERATIONS        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a minimal ERC1967I proxy with `implementation` and `args`.
    function deployERC1967I(address implementation, bytes memory args) internal returns (address) {
        return deployERC1967I(0, implementation, args);
    }

    /// @dev Deploys a minimal ERC1967I proxy with `implementation` and `args`.
    /// Deposits `value` ETH during deployment.
    function deployERC1967I(
        uint256 value,
        address implementation,
        bytes memory args
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x8b), n))

            mstore(add(m, 0x6b), 0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3)
            mstore(add(m, 0x4b), 0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4)
            mstore(add(m, 0x2b), 0x600f5155f3365814604357363d3d373d3d363d7f360894)
            mstore(add(m, 0x14), implementation)
            mstore(m, add(0xfe6100523d8160233d3973, shl(56, n)))

            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x52 = 0xffad`.
            instance := create(value, add(m, add(0x15, lt(n, 0xffae))), add(0x75, n))
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Deploys a deterministic ERC1967I proxy with `implementation`, `args`, and `salt`.
    function deployDeterministicERC1967I(
        address implementation,
        bytes memory args,
        bytes32 salt
    ) internal returns (address instance) {
        instance = deployDeterministicERC1967I(0, implementation, args, salt);
    }

    /// @dev Deploys a deterministic ERC1967I proxy with `implementation`, `args`, and `salt`.
    /// Deposits `value` ETH during deployment.
    function deployDeterministicERC1967I(
        uint256 value,
        address implementation,
        bytes memory args,
        bytes32 salt
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x8b), n))

            mstore(add(m, 0x6b), 0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3)
            mstore(add(m, 0x4b), 0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4)
            mstore(add(m, 0x2b), 0x600f5155f3365814604357363d3d373d3d363d7f360894)
            mstore(add(m, 0x14), implementation)
            mstore(m, add(0xfe6100523d8160233d3973, shl(56, n)))

            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x52 = 0xffad`.
            instance := create2(value, add(m, add(0x15, lt(n, 0xffae))), add(0x75, n), salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Creates a deterministic ERC1967I proxy with `implementation`, `args` and `salt`.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967I(
        address implementation,
        bytes memory args,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        return createDeterministicERC1967I(0, implementation, args, salt);
    }

    /// @dev Creates a deterministic ERC1967I proxy with `implementation`, `args` and `salt`.
    /// Deposits `value` ETH during deployment.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967I(
        uint256 value,
        address implementation,
        bytes memory args,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x75), n))
            mstore(add(m, 0x55), 0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3)
            mstore(add(m, 0x35), 0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4)
            mstore(add(m, 0x15), 0x5155f3365814604357363d3d373d3d363d7f360894)
            mstore(0x16, 0x600f)
            mstore(0x14, implementation)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x52 = 0xffad`.
            mstore(gt(n, 0xffad), add(0xfe6100523d8160233d3973, shl(56, n)))
            mstore(m, mload(0x16))
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, keccak256(m, add(n, 0x75)))
            mstore(0x01, shl(96, address()))
            mstore(0x15, salt)
            instance := keccak256(0x00, 0x55)
            for {

            } 1 {

            } {
                if iszero(extcodesize(instance)) {
                    instance := create2(value, m, add(0x75, n), salt)
                    if iszero(instance) {
                        mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                        revert(0x1c, 0x04)
                    }
                    break
                }
                alreadyDeployed := 1
                if iszero(value) {
                    break
                }
                if iszero(call(gas(), instance, value, codesize(), 0x00, codesize(), 0x00)) {
                    mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                    revert(0x1c, 0x04)
                }
                break
            }
            mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the initialization code of the ERC1967I proxy of `implementation` and `args`.
    function initCodeERC1967I(address implementation, bytes memory args) internal pure returns (bytes memory c) {
        /// @solidity memory-safe-assembly
        assembly {
            c := mload(0x40)
            let n := mload(args)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x52 = 0xffad`.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0xffad))
            for {
                let i := 0
            } lt(i, n) {
                i := add(i, 0x20)
            } {
                mstore(add(add(c, 0x95), i), mload(add(add(args, 0x20), i)))
            }

            mstore(add(c, 0x75), 0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3)
            mstore(add(c, 0x55), 0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4)
            mstore(add(c, 0x35), 0x600f5155f3365814604357363d3d373d3d363d7f360894)
            mstore(add(c, 0x1e), implementation)
            mstore(add(c, 0x0a), add(0x6100523d8160233d3973, shl(56, n)))
            mstore(add(c, add(n, 0x95)), 0)
            mstore(c, add(0x75, n)) // Store the length.
            mstore(0x40, add(c, add(n, 0xb5))) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the ERC1967I proxy of `implementation` and `args.
    function initCodeHashERC1967I(address implementation, bytes memory args) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            let n := mload(args)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x52 = 0xffad`.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0xffad))

            for {
                let i := 0
            } lt(i, n) {
                i := add(i, 0x20)
            } {
                mstore(add(add(m, 0x75), i), mload(add(add(args, 0x20), i)))
            }

            mstore(add(m, 0x55), 0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3)
            mstore(add(m, 0x35), 0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4)
            mstore(add(m, 0x15), 0x5155f3365814604357363d3d373d3d363d7f360894)
            mstore(0x16, 0x600f)
            mstore(0x14, implementation)
            mstore(0x00, add(0x6100523d8160233d3973, shl(56, n)))
            mstore(m, mload(0x16))
            hash := keccak256(m, add(0x75, n))
        }
    }

    /// @dev Returns the address of the ERC1967I proxy of `implementation`, `args` with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddressERC1967I(
        address implementation,
        bytes memory args,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHashERC1967I(implementation, args);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /// @dev Equivalent to `argsOnERC1967I(instance, start, 2 ** 256 - 1)`.
    function argsOnERC1967I(address instance) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            mstore(args, and(0xffffffffff, sub(extcodesize(instance), 0x52))) // Store the length.
            extcodecopy(instance, add(args, 0x20), 0x52, add(mload(args), 0x20))
            mstore(0x40, add(mload(args), add(args, 0x40))) // Allocate memory.
        }
    }

    /// @dev Equivalent to `argsOnERC1967I(instance, start, 2 ** 256 - 1)`.
    function argsOnERC1967I(address instance, uint256 start) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            let n := and(0xffffffffff, sub(extcodesize(instance), 0x52))
            let l := sub(n, and(0xffffff, mul(lt(start, n), start)))
            extcodecopy(instance, args, add(start, 0x32), add(l, 0x40))
            mstore(args, mul(sub(n, start), lt(start, n))) // Store the length.
            mstore(0x40, add(mload(args), add(args, 0x40))) // Allocate memory.
        }
    }

    /// @dev Returns a slice of the immutable arguments on `instance` from `start` to `end`.
    /// `start` and `end` will be clamped to the range `[0, args.length]`.
    /// The `instance` MUST be deployed via the ERC1967 with immutable args functions.
    /// Otherwise, the behavior is undefined.
    /// Out-of-gas reverts if `instance` does not have any code.
    function argsOnERC1967I(address instance, uint256 start, uint256 end) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            if iszero(lt(end, 0xffff)) {
                end := 0xffff
            }
            let d := mul(sub(end, start), lt(start, end))
            extcodecopy(instance, args, add(start, 0x32), add(d, 0x20))
            if iszero(and(0xff, mload(add(args, d)))) {
                let n := sub(extcodesize(instance), 0x52)
                returndatacopy(returndatasize(), returndatasize(), shr(40, n))
                d := mul(gt(n, start), sub(d, mul(gt(end, n), sub(end, n))))
            }
            mstore(args, d) // Store the length.
            mstore(add(add(args, 0x20), d), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(add(args, 0x40), d)) // Allocate memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                ERC1967 BOOTSTRAP OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // A bootstrap is a minimal UUPS implementation that allows an ERC1967 proxy
    // pointing to it to be upgraded. The ERC1967 proxy can then be deployed to a
    // deterministic address independent of the implementation:
    // ```
    //     address bootstrap = LibClone.erc1967Bootstrap();
    //     address instance = LibClone.deployDeterministicERC1967(0, bootstrap, salt);
    //     LibClone.bootstrapERC1967(bootstrap, implementation);
    // ```

    /// @dev Deploys the ERC1967 bootstrap if it has not been deployed.
    function erc1967Bootstrap() internal returns (address) {
        return erc1967Bootstrap(address(this));
    }

    /// @dev Deploys the ERC1967 bootstrap if it has not been deployed.
    function erc1967Bootstrap(address authorizedUpgrader) internal returns (address bootstrap) {
        bytes memory c = initCodeERC1967Bootstrap(authorizedUpgrader);
        bootstrap = predictDeterministicAddress(keccak256(c), bytes32(0), address(this));
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(extcodesize(bootstrap)) {
                if iszero(create2(0, add(c, 0x20), mload(c), 0)) {
                    mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /// @dev Replaces the implementation at `instance`.
    function bootstrapERC1967(address instance, address implementation) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, implementation)
            if iszero(call(gas(), instance, 0, 0x0c, 0x14, codesize(), 0x00)) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Replaces the implementation at `instance`, and then call it with `data`.
    function bootstrapERC1967AndCall(address instance, address implementation, bytes memory data) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(data)
            mstore(data, implementation)
            if iszero(call(gas(), instance, 0, add(data, 0x0c), add(n, 0x14), codesize(), 0x00)) {
                if iszero(returndatasize()) {
                    mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                    revert(0x1c, 0x04)
                }
                returndatacopy(mload(0x40), 0x00, returndatasize())
                revert(mload(0x40), returndatasize())
            }
            mstore(data, n) // Restore the length of `data`.
        }
    }

    /// @dev Returns the implementation address of the ERC1967 bootstrap for this contract.
    function predictDeterministicAddressERC1967Bootstrap() internal view returns (address) {
        return predictDeterministicAddressERC1967Bootstrap(address(this), address(this));
    }

    /// @dev Returns the implementation address of the ERC1967 bootstrap for this contract.
    function predictDeterministicAddressERC1967Bootstrap(
        address authorizedUpgrader,
        address deployer
    ) internal pure returns (address) {
        bytes32 hash = initCodeHashERC1967Bootstrap(authorizedUpgrader);
        return predictDeterministicAddress(hash, bytes32(0), deployer);
    }

    /// @dev Returns the initialization code of the ERC1967 bootstrap.
    function initCodeERC1967Bootstrap(address authorizedUpgrader) internal pure returns (bytes memory c) {
        /// @solidity memory-safe-assembly
        assembly {
            c := mload(0x40)
            mstore(add(c, 0x80), 0x3d3560601c5af46047573d6000383e3d38fd0000000000000000000000000000)
            mstore(add(c, 0x60), 0xa920a3ca505d382bbc55601436116049575b005b363d3d373d3d601436036014)
            mstore(add(c, 0x40), 0x0338573d3560601c7f360894a13ba1a3210667c828492db98dca3e2076cc3735)
            mstore(add(c, 0x20), authorizedUpgrader)
            mstore(add(c, 0x0c), 0x606880600a3d393df3fe3373)
            mstore(c, 0x72)
            mstore(0x40, add(c, 0xa0))
        }
    }

    /// @dev Returns the initialization code hash of the ERC1967 bootstrap.
    function initCodeHashERC1967Bootstrap(address authorizedUpgrader) internal pure returns (bytes32) {
        return keccak256(initCodeERC1967Bootstrap(authorizedUpgrader));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          MINIMAL ERC1967 BEACON PROXY OPERATIONS           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note: If you use this proxy, you MUST make sure that the beacon is a
    // valid ERC1967 beacon. This means that the beacon must always return a valid
    // address upon a staticcall to `implementation()`, given sufficient gas.
    // For performance, the deployment operations and the proxy assumes that the
    // beacon is always valid and will NOT validate it.

    /// @dev Deploys a minimal ERC1967 beacon proxy.
    function deployERC1967BeaconProxy(address beacon) internal returns (address instance) {
        instance = deployERC1967BeaconProxy(0, beacon);
    }

    /// @dev Deploys a minimal ERC1967 beacon proxy.
    /// Deposits `value` ETH during deployment.
    function deployERC1967BeaconProxy(uint256 value, address beacon) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * ---------------------------------------------------------------------------------+
             * CREATION (34 bytes)                                                              |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize  | r                |                                 |
             * 3d         | RETURNDATASIZE | 0 r              |                                 |
             * 81         | DUP2           | r 0 r            |                                 |
             * 60 offset  | PUSH1 offset   | o r 0 r          |                                 |
             * 3d         | RETURNDATASIZE | 0 o r 0 r        |                                 |
             * 39         | CODECOPY       | 0 r              | [0..runSize): runtime code      |
             * 73 beac    | PUSH20 beac    | beac 0 r         | [0..runSize): runtime code      |
             * 60 slotPos | PUSH1 slotPos  | slotPos beac 0 r | [0..runSize): runtime code      |
             * 51         | MLOAD          | slot beac 0 r    | [0..runSize): runtime code      |
             * 55         | SSTORE         | 0 r              | [0..runSize): runtime code      |
             * f3         | RETURN         |                  | [0..runSize): runtime code      |
             * ---------------------------------------------------------------------------------|
             * RUNTIME (82 bytes)                                                               |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             *                                                                                  |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36         | CALLDATASIZE   | cds              |                                 |
             * 3d         | RETURNDATASIZE | 0 cds            |                                 |
             * 3d         | RETURNDATASIZE | 0 0 cds          |                                 |
             * 37         | CALLDATACOPY   |                  | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: delegatecall to implementation ::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | 0                |                                 |
             * 3d         | RETURNDATASIZE | 0 0              |                                 |
             * 36         | CALLDATASIZE   | cds 0 0          | [0..calldatasize): calldata     |
             * 3d         | RETURNDATASIZE | 0 cds 0 0        | [0..calldatasize): calldata     |
             *                                                                                  |
             * ~~~~~~~ beacon staticcall sub procedure ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ |
             * 60 0x20       | PUSH1 0x20       | 32                          |                 |
             * 36            | CALLDATASIZE     | cds 32                      |                 |
             * 60 0x04       | PUSH1 0x04       | 4 cds 32                    |                 |
             * 36            | CALLDATASIZE     | cds 4 cds 32                |                 |
             * 63 0x5c60da1b | PUSH4 0x5c60da1b | 0x5c60da1b cds 4 cds 32     |                 |
             * 60 0xe0       | PUSH1 0xe0       | 224 0x5c60da1b cds 4 cds 32 |                 |
             * 1b            | SHL              | sel cds 4 cds 32            |                 |
             * 36            | CALLDATASIZE     | cds sel cds 4 cds 32        |                 |
             * 52            | MSTORE           | cds 4 cds 32                | sel             |
             * 7f slot       | PUSH32 slot      | s cds 4 cds 32              | sel             |
             * 54            | SLOAD            | beac cds 4 cds 32           | sel             |
             * 5a            | GAS              | g beac cds 4 cds 32         | sel             |
             * fa            | STATICCALL       | succ                        | impl            |
             * 50            | POP              |                             | impl            |
             * 36            | CALLDATASIZE     | cds                         | impl            |
             * 51            | MLOAD            | impl                        | impl            |
             * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ |
             * 5a         | GAS            | g impl 0 cds 0 0 | [0..calldatasize): calldata     |
             * f4         | DELEGATECALL   | succ             | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: copy returndata to memory :::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds succ         | [0..calldatasize): calldata     |
             * 60 0x00    | PUSH1 0x00     | 0 rds succ       | [0..calldatasize): calldata     |
             * 80         | DUP1           | 0 0 rds succ     | [0..calldatasize): calldata     |
             * 3e         | RETURNDATACOPY | succ             | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: branch on delegatecall status :::::::::::::::::::::::::::::::::::::::::::::: |
             * 60 0x4d    | PUSH1 0x4d     | dest succ        | [0..returndatasize): returndata |
             * 57         | JUMPI          |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall failed, revert :::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds              | [0..returndatasize): returndata |
             * 60 0x00    | PUSH1 0x00     | 0 rds            | [0..returndatasize): returndata |
             * fd         | REVERT         |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall succeeded, return ::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b         | JUMPDEST       |                  | [0..returndatasize): returndata |
             * 3d         | RETURNDATASIZE | rds              | [0..returndatasize): returndata |
             * 60 0x00    | PUSH1 0x00     | 0 rds            | [0..returndatasize): returndata |
             * f3         | RETURN         |                  | [0..returndatasize): returndata |
             * ---------------------------------------------------------------------------------+
             */
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xb3582b35133d50545afa5036515af43d6000803e604d573d6000fd5b3d6000f3)
            mstore(0x40, 0x1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6c)
            mstore(0x20, 0x60195155f3363d3d373d3d363d602036600436635c60da)
            mstore(0x09, or(shl(160, 0x60523d8160223d3973), shr(96, shl(96, beacon))))
            instance := create(value, 0x0c, 0x74)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Deploys a deterministic minimal ERC1967 beacon proxy with `salt`.
    function deployDeterministicERC1967BeaconProxy(address beacon, bytes32 salt) internal returns (address instance) {
        instance = deployDeterministicERC1967BeaconProxy(0, beacon, salt);
    }

    /// @dev Deploys a deterministic minimal ERC1967 beacon proxy with `salt`.
    /// Deposits `value` ETH during deployment.
    function deployDeterministicERC1967BeaconProxy(
        uint256 value,
        address beacon,
        bytes32 salt
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xb3582b35133d50545afa5036515af43d6000803e604d573d6000fd5b3d6000f3)
            mstore(0x40, 0x1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6c)
            mstore(0x20, 0x60195155f3363d3d373d3d363d602036600436635c60da)
            mstore(0x09, or(shl(160, 0x60523d8160223d3973), shr(96, shl(96, beacon))))
            instance := create2(value, 0x0c, 0x74, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Creates a deterministic minimal ERC1967 beacon proxy with `salt`.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967BeaconProxy(
        address beacon,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        return createDeterministicERC1967BeaconProxy(0, beacon, salt);
    }

    /// @dev Creates a deterministic minimal ERC1967 beacon proxy with `salt`.
    /// Deposits `value` ETH during deployment.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967BeaconProxy(
        uint256 value,
        address beacon,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xb3582b35133d50545afa5036515af43d6000803e604d573d6000fd5b3d6000f3)
            mstore(0x40, 0x1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6c)
            mstore(0x20, 0x60195155f3363d3d373d3d363d602036600436635c60da)
            mstore(0x09, or(shl(160, 0x60523d8160223d3973), shr(96, shl(96, beacon))))
            // Compute and store the bytecode hash.
            mstore(add(m, 0x35), keccak256(0x0c, 0x74))
            mstore(m, shl(88, address()))
            mstore8(m, 0xff) // Write the prefix.
            mstore(add(m, 0x15), salt)
            instance := keccak256(m, 0x55)
            for {

            } 1 {

            } {
                if iszero(extcodesize(instance)) {
                    instance := create2(value, 0x0c, 0x74, salt)
                    if iszero(instance) {
                        mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                        revert(0x1c, 0x04)
                    }
                    break
                }
                alreadyDeployed := 1
                if iszero(value) {
                    break
                }
                if iszero(call(gas(), instance, value, codesize(), 0x00, codesize(), 0x00)) {
                    mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                    revert(0x1c, 0x04)
                }
                break
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the initialization code of the minimal ERC1967 beacon proxy.
    function initCodeERC1967BeaconProxy(address beacon) internal pure returns (bytes memory c) {
        /// @solidity memory-safe-assembly
        assembly {
            c := mload(0x40)
            mstore(add(c, 0x74), 0xb3582b35133d50545afa5036515af43d6000803e604d573d6000fd5b3d6000f3)
            mstore(add(c, 0x54), 0x1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6c)
            mstore(add(c, 0x34), 0x60195155f3363d3d373d3d363d602036600436635c60da)
            mstore(add(c, 0x1d), beacon)
            mstore(add(c, 0x09), 0x60523d8160223d3973)
            mstore(add(c, 0x94), 0)
            mstore(c, 0x74) // Store the length.
            mstore(0x40, add(c, 0xa0)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the minimal ERC1967 beacon proxy.
    function initCodeHashERC1967BeaconProxy(address beacon) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xb3582b35133d50545afa5036515af43d6000803e604d573d6000fd5b3d6000f3)
            mstore(0x40, 0x1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6c)
            mstore(0x20, 0x60195155f3363d3d373d3d363d602036600436635c60da)
            mstore(0x09, or(shl(160, 0x60523d8160223d3973), shr(96, shl(96, beacon))))
            hash := keccak256(0x0c, 0x74)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the address of the ERC1967 beacon proxy, with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddressERC1967BeaconProxy(
        address beacon,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHashERC1967BeaconProxy(beacon);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*    ERC1967 BEACON PROXY WITH IMMUTABLE ARGS OPERATIONS     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a minimal ERC1967 beacon proxy with `args`.
    function deployERC1967BeaconProxy(address beacon, bytes memory args) internal returns (address instance) {
        instance = deployERC1967BeaconProxy(0, beacon, args);
    }

    /// @dev Deploys a minimal ERC1967 beacon proxy with `args`.
    /// Deposits `value` ETH during deployment.
    function deployERC1967BeaconProxy(
        uint256 value,
        address beacon,
        bytes memory args
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x8b), n))
            mstore(add(m, 0x6b), 0xb3582b35133d50545afa5036515af43d6000803e604d573d6000fd5b3d6000f3)
            mstore(add(m, 0x4b), 0x1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6c)
            mstore(add(m, 0x2b), 0x60195155f3363d3d373d3d363d602036600436635c60da)
            mstore(add(m, 0x14), beacon)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x52 = 0xffad`.
            mstore(add(m, gt(n, 0xffad)), add(0xfe6100523d8160233d3973, shl(56, n)))
            instance := create(value, add(m, 0x16), add(n, 0x75))
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Deploys a deterministic minimal ERC1967 beacon proxy with `args` and `salt`.
    function deployDeterministicERC1967BeaconProxy(
        address beacon,
        bytes memory args,
        bytes32 salt
    ) internal returns (address instance) {
        instance = deployDeterministicERC1967BeaconProxy(0, beacon, args, salt);
    }

    /// @dev Deploys a deterministic minimal ERC1967 beacon proxy with `args` and `salt`.
    /// Deposits `value` ETH during deployment.
    function deployDeterministicERC1967BeaconProxy(
        uint256 value,
        address beacon,
        bytes memory args,
        bytes32 salt
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x8b), n))
            mstore(add(m, 0x6b), 0xb3582b35133d50545afa5036515af43d6000803e604d573d6000fd5b3d6000f3)
            mstore(add(m, 0x4b), 0x1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6c)
            mstore(add(m, 0x2b), 0x60195155f3363d3d373d3d363d602036600436635c60da)
            mstore(add(m, 0x14), beacon)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x52 = 0xffad`.
            mstore(add(m, gt(n, 0xffad)), add(0xfe6100523d8160233d3973, shl(56, n)))
            instance := create2(value, add(m, 0x16), add(n, 0x75), salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Creates a deterministic minimal ERC1967 beacon proxy with `args` and `salt`.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967BeaconProxy(
        address beacon,
        bytes memory args,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        return createDeterministicERC1967BeaconProxy(0, beacon, args, salt);
    }

    /// @dev Creates a deterministic minimal ERC1967 beacon proxy with `args` and `salt`.
    /// Deposits `value` ETH during deployment.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967BeaconProxy(
        uint256 value,
        address beacon,
        bytes memory args,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x8b), n))
            mstore(add(m, 0x6b), 0xb3582b35133d50545afa5036515af43d6000803e604d573d6000fd5b3d6000f3)
            mstore(add(m, 0x4b), 0x1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6c)
            mstore(add(m, 0x2b), 0x60195155f3363d3d373d3d363d602036600436635c60da)
            mstore(add(m, 0x14), beacon)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x52 = 0xffad`.
            mstore(add(m, gt(n, 0xffad)), add(0xfe6100523d8160233d3973, shl(56, n)))
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, keccak256(add(m, 0x16), add(n, 0x75)))
            mstore(0x01, shl(96, address()))
            mstore(0x15, salt)
            instance := keccak256(0x00, 0x55)
            for {

            } 1 {

            } {
                if iszero(extcodesize(instance)) {
                    instance := create2(value, add(m, 0x16), add(n, 0x75), salt)
                    if iszero(instance) {
                        mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                        revert(0x1c, 0x04)
                    }
                    break
                }
                alreadyDeployed := 1
                if iszero(value) {
                    break
                }
                if iszero(call(gas(), instance, value, codesize(), 0x00, codesize(), 0x00)) {
                    mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                    revert(0x1c, 0x04)
                }
                break
            }
            mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the initialization code of the minimal ERC1967 beacon proxy.
    function initCodeERC1967BeaconProxy(address beacon, bytes memory args) internal pure returns (bytes memory c) {
        /// @solidity memory-safe-assembly
        assembly {
            c := mload(0x40)
            let n := mload(args)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x52 = 0xffad`.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0xffad))
            for {
                let i := 0
            } lt(i, n) {
                i := add(i, 0x20)
            } {
                mstore(add(add(c, 0x95), i), mload(add(add(args, 0x20), i)))
            }
            mstore(add(c, 0x75), 0xb3582b35133d50545afa5036515af43d6000803e604d573d6000fd5b3d6000f3)
            mstore(add(c, 0x55), 0x1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6c)
            mstore(add(c, 0x35), 0x60195155f3363d3d373d3d363d602036600436635c60da)
            mstore(add(c, 0x1e), beacon)
            mstore(add(c, 0x0a), add(0x6100523d8160233d3973, shl(56, n)))
            mstore(c, add(n, 0x75)) // Store the length.
            mstore(add(c, add(n, 0x95)), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(c, add(n, 0xb5))) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the minimal ERC1967 beacon proxy with `args`.
    function initCodeHashERC1967BeaconProxy(address beacon, bytes memory args) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x52 = 0xffad`.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0xffad))
            for {
                let i := 0
            } lt(i, n) {
                i := add(i, 0x20)
            } {
                mstore(add(add(m, 0x8b), i), mload(add(add(args, 0x20), i)))
            }
            mstore(add(m, 0x6b), 0xb3582b35133d50545afa5036515af43d6000803e604d573d6000fd5b3d6000f3)
            mstore(add(m, 0x4b), 0x1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6c)
            mstore(add(m, 0x2b), 0x60195155f3363d3d373d3d363d602036600436635c60da)
            mstore(add(m, 0x14), beacon)
            mstore(m, add(0x6100523d8160233d3973, shl(56, n)))
            hash := keccak256(add(m, 0x16), add(n, 0x75))
        }
    }

    /// @dev Returns the address of the ERC1967 beacon proxy with `args`, with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddressERC1967BeaconProxy(
        address beacon,
        bytes memory args,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHashERC1967BeaconProxy(beacon, args);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /// @dev Equivalent to `argsOnERC1967BeaconProxy(instance, start, 2 ** 256 - 1)`.
    function argsOnERC1967BeaconProxy(address instance) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            mstore(args, and(0xffffffffff, sub(extcodesize(instance), 0x52))) // Store the length.
            extcodecopy(instance, add(args, 0x20), 0x52, add(mload(args), 0x20))
            mstore(0x40, add(mload(args), add(args, 0x40))) // Allocate memory.
        }
    }

    /// @dev Equivalent to `argsOnERC1967BeaconProxy(instance, start, 2 ** 256 - 1)`.
    function argsOnERC1967BeaconProxy(address instance, uint256 start) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            let n := and(0xffffffffff, sub(extcodesize(instance), 0x52))
            let l := sub(n, and(0xffffff, mul(lt(start, n), start)))
            extcodecopy(instance, args, add(start, 0x32), add(l, 0x40))
            mstore(args, mul(sub(n, start), lt(start, n))) // Store the length.
            mstore(0x40, add(args, add(0x40, mload(args)))) // Allocate memory.
        }
    }

    /// @dev Returns a slice of the immutable arguments on `instance` from `start` to `end`.
    /// `start` and `end` will be clamped to the range `[0, args.length]`.
    /// The `instance` MUST be deployed via the ERC1967 beacon proxy with immutable args functions.
    /// Otherwise, the behavior is undefined.
    /// Out-of-gas reverts if `instance` does not have any code.
    function argsOnERC1967BeaconProxy(
        address instance,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            if iszero(lt(end, 0xffff)) {
                end := 0xffff
            }
            let d := mul(sub(end, start), lt(start, end))
            extcodecopy(instance, args, add(start, 0x32), add(d, 0x20))
            if iszero(and(0xff, mload(add(args, d)))) {
                let n := sub(extcodesize(instance), 0x52)
                returndatacopy(returndatasize(), returndatasize(), shr(40, n))
                d := mul(gt(n, start), sub(d, mul(gt(end, n), sub(end, n))))
            }
            mstore(args, d) // Store the length.
            mstore(add(add(args, 0x20), d), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(add(args, 0x40), d)) // Allocate memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              ERC1967I BEACON PROXY OPERATIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note: This proxy has a special code path that activates if `calldatasize() == 1`.
    // This code path skips the delegatecall and directly returns the `implementation` address.
    // The returned implementation is guaranteed to be valid if the keccak256 of the
    // proxy's code is equal to `ERC1967_BEACON_PROXY_CODE_HASH`.
    //
    // If you use this proxy, you MUST make sure that the beacon is a
    // valid ERC1967 beacon. This means that the beacon must always return a valid
    // address upon a staticcall to `implementation()`, given sufficient gas.
    // For performance, the deployment operations and the proxy assumes that the
    // beacon is always valid and will NOT validate it.

    /// @dev Deploys a ERC1967I beacon proxy.
    function deployERC1967IBeaconProxy(address beacon) internal returns (address instance) {
        instance = deployERC1967IBeaconProxy(0, beacon);
    }

    /// @dev Deploys a ERC1967I beacon proxy.
    /// Deposits `value` ETH during deployment.
    function deployERC1967IBeaconProxy(uint256 value, address beacon) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * ---------------------------------------------------------------------------------+
             * CREATION (34 bytes)                                                              |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize  | r                |                                 |
             * 3d         | RETURNDATASIZE | 0 r              |                                 |
             * 81         | DUP2           | r 0 r            |                                 |
             * 60 offset  | PUSH1 offset   | o r 0 r          |                                 |
             * 3d         | RETURNDATASIZE | 0 o r 0 r        |                                 |
             * 39         | CODECOPY       | 0 r              | [0..runSize): runtime code      |
             * 73 beac    | PUSH20 beac    | beac 0 r         | [0..runSize): runtime code      |
             * 60 slotPos | PUSH1 slotPos  | slotPos beac 0 r | [0..runSize): runtime code      |
             * 51         | MLOAD          | slot beac 0 r    | [0..runSize): runtime code      |
             * 55         | SSTORE         | 0 r              | [0..runSize): runtime code      |
             * f3         | RETURN         |                  | [0..runSize): runtime code      |
             * ---------------------------------------------------------------------------------|
             * RUNTIME (87 bytes)                                                               |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             *                                                                                  |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36         | CALLDATASIZE   | cds              |                                 |
             * 3d         | RETURNDATASIZE | 0 cds            |                                 |
             * 3d         | RETURNDATASIZE | 0 0 cds          |                                 |
             * 37         | CALLDATACOPY   |                  | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: delegatecall to implementation ::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | 0                |                                 |
             * 3d         | RETURNDATASIZE | 0 0              |                                 |
             * 36         | CALLDATASIZE   | cds 0 0          | [0..calldatasize): calldata     |
             * 3d         | RETURNDATASIZE | 0 cds 0 0        | [0..calldatasize): calldata     |
             *                                                                                  |
             * ~~~~~~~ beacon staticcall sub procedure ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ |
             * 60 0x20       | PUSH1 0x20       | 32                          |                 |
             * 36            | CALLDATASIZE     | cds 32                      |                 |
             * 60 0x04       | PUSH1 0x04       | 4 cds 32                    |                 |
             * 36            | CALLDATASIZE     | cds 4 cds 32                |                 |
             * 63 0x5c60da1b | PUSH4 0x5c60da1b | 0x5c60da1b cds 4 cds 32     |                 |
             * 60 0xe0       | PUSH1 0xe0       | 224 0x5c60da1b cds 4 cds 32 |                 |
             * 1b            | SHL              | sel cds 4 cds 32            |                 |
             * 36            | CALLDATASIZE     | cds sel cds 4 cds 32        |                 |
             * 52            | MSTORE           | cds 4 cds 32                | sel             |
             * 7f slot       | PUSH32 slot      | s cds 4 cds 32              | sel             |
             * 54            | SLOAD            | beac cds 4 cds 32           | sel             |
             * 5a            | GAS              | g beac cds 4 cds 32         | sel             |
             * fa            | STATICCALL       | succ                        | impl            |
             * ~~~~~~ check calldatasize ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ |
             * 36            | CALLDATASIZE     | cds succ                    |                 |
             * 14            | EQ               |                             | impl            |
             * 60 0x52       | PUSH1 0x52       |                             | impl            |
             * 57            | JUMPI            |                             | impl            |
             * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ |
             * 36            | CALLDATASIZE     | cds                         | impl            |
             * 51            | MLOAD            | impl                        | impl            |
             * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ |
             * 5a         | GAS            | g impl 0 cds 0 0 | [0..calldatasize): calldata     |
             * f4         | DELEGATECALL   | succ             | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: copy returndata to memory :::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds succ         | [0..calldatasize): calldata     |
             * 60 0x00    | PUSH1 0x00     | 0 rds succ       | [0..calldatasize): calldata     |
             * 60 0x01    | PUSH1 0x01     | 1 0 rds succ     | [0..calldatasize): calldata     |
             * 3e         | RETURNDATACOPY | succ             | [1..returndatasize): returndata |
             *                                                                                  |
             * ::: branch on delegatecall status :::::::::::::::::::::::::::::::::::::::::::::: |
             * 60 0x52    | PUSH1 0x52     | dest succ        | [1..returndatasize): returndata |
             * 57         | JUMPI          |                  | [1..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall failed, revert :::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds              | [1..returndatasize): returndata |
             * 60 0x01    | PUSH1 0x01     | 1 rds            | [1..returndatasize): returndata |
             * fd         | REVERT         |                  | [1..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall succeeded, return ::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b         | JUMPDEST       |                  | [1..returndatasize): returndata |
             * 3d         | RETURNDATASIZE | rds              | [1..returndatasize): returndata |
             * 60 0x01    | PUSH1 0x01     | 1 rds            | [1..returndatasize): returndata |
             * f3         | RETURN         |                  | [1..returndatasize): returndata |
             * ---------------------------------------------------------------------------------+
             */
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0x3d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3)
            mstore(0x40, 0x527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b3513)
            mstore(0x20, 0x60195155f3363d3d373d3d363d602036600436635c60da1b60e01b36)
            mstore(0x04, or(shl(160, 0x60573d8160223d3973), shr(96, shl(96, beacon))))
            instance := create(value, 0x07, 0x79)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Deploys a deterministic ERC1967I beacon proxy with `salt`.
    function deployDeterministicERC1967IBeaconProxy(address beacon, bytes32 salt) internal returns (address instance) {
        instance = deployDeterministicERC1967IBeaconProxy(0, beacon, salt);
    }

    /// @dev Deploys a deterministic ERC1967I beacon proxy with `salt`.
    /// Deposits `value` ETH during deployment.
    function deployDeterministicERC1967IBeaconProxy(
        uint256 value,
        address beacon,
        bytes32 salt
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0x3d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3)
            mstore(0x40, 0x527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b3513)
            mstore(0x20, 0x60195155f3363d3d373d3d363d602036600436635c60da1b60e01b36)
            mstore(0x04, or(shl(160, 0x60573d8160223d3973), shr(96, shl(96, beacon))))
            instance := create2(value, 0x07, 0x79, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Creates a deterministic ERC1967I beacon proxy with `salt`.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967IBeaconProxy(
        address beacon,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        return createDeterministicERC1967IBeaconProxy(0, beacon, salt);
    }

    /// @dev Creates a deterministic ERC1967I beacon proxy with `salt`.
    /// Deposits `value` ETH during deployment.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967IBeaconProxy(
        uint256 value,
        address beacon,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0x3d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3)
            mstore(0x40, 0x527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b3513)
            mstore(0x20, 0x60195155f3363d3d373d3d363d602036600436635c60da1b60e01b36)
            mstore(0x04, or(shl(160, 0x60573d8160223d3973), shr(96, shl(96, beacon))))
            // Compute and store the bytecode hash.
            mstore(add(m, 0x35), keccak256(0x07, 0x79))
            mstore(m, shl(88, address()))
            mstore8(m, 0xff) // Write the prefix.
            mstore(add(m, 0x15), salt)
            instance := keccak256(m, 0x55)
            for {

            } 1 {

            } {
                if iszero(extcodesize(instance)) {
                    instance := create2(value, 0x07, 0x79, salt)
                    if iszero(instance) {
                        mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                        revert(0x1c, 0x04)
                    }
                    break
                }
                alreadyDeployed := 1
                if iszero(value) {
                    break
                }
                if iszero(call(gas(), instance, value, codesize(), 0x00, codesize(), 0x00)) {
                    mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                    revert(0x1c, 0x04)
                }
                break
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the initialization code of the ERC1967I beacon proxy.
    function initCodeERC1967IBeaconProxy(address beacon) internal pure returns (bytes memory c) {
        /// @solidity memory-safe-assembly
        assembly {
            c := mload(0x40)
            mstore(add(c, 0x79), 0x3d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3)
            mstore(add(c, 0x59), 0x527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b3513)
            mstore(add(c, 0x39), 0x60195155f3363d3d373d3d363d602036600436635c60da1b60e01b36)
            mstore(add(c, 0x1d), beacon)
            mstore(add(c, 0x09), 0x60573d8160223d3973)
            mstore(add(c, 0x99), 0)
            mstore(c, 0x79) // Store the length.
            mstore(0x40, add(c, 0xa0)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the ERC1967I beacon proxy.
    function initCodeHashERC1967IBeaconProxy(address beacon) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0x3d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3)
            mstore(0x40, 0x527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b3513)
            mstore(0x20, 0x60195155f3363d3d373d3d363d602036600436635c60da1b60e01b36)
            mstore(0x04, or(shl(160, 0x60573d8160223d3973), shr(96, shl(96, beacon))))
            hash := keccak256(0x07, 0x79)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the address of the ERC1967I beacon proxy, with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddressERC1967IBeaconProxy(
        address beacon,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHashERC1967IBeaconProxy(beacon);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*    ERC1967I BEACON PROXY WITH IMMUTABLE ARGS OPERATIONS    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a ERC1967I beacon proxy with `args.
    function deployERC1967IBeaconProxy(address beacon, bytes memory args) internal returns (address instance) {
        instance = deployERC1967IBeaconProxy(0, beacon, args);
    }

    /// @dev Deploys a ERC1967I beacon proxy with `args.
    /// Deposits `value` ETH during deployment.
    function deployERC1967IBeaconProxy(
        uint256 value,
        address beacon,
        bytes memory args
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x90), n))
            mstore(add(m, 0x70), 0x3d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3)
            mstore(add(m, 0x50), 0x527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b3513)
            mstore(add(m, 0x30), 0x60195155f3363d3d373d3d363d602036600436635c60da1b60e01b36)
            mstore(add(m, 0x14), beacon)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x57 = 0xffa8`.
            mstore(add(m, gt(n, 0xffa8)), add(0xfe6100573d8160233d3973, shl(56, n)))
            instance := create(value, add(m, 0x16), add(n, 0x7a))
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Deploys a deterministic ERC1967I beacon proxy with `args` and `salt`.
    function deployDeterministicERC1967IBeaconProxy(
        address beacon,
        bytes memory args,
        bytes32 salt
    ) internal returns (address instance) {
        instance = deployDeterministicERC1967IBeaconProxy(0, beacon, args, salt);
    }

    /// @dev Deploys a deterministic ERC1967I beacon proxy with `args` and `salt`.
    /// Deposits `value` ETH during deployment.
    function deployDeterministicERC1967IBeaconProxy(
        uint256 value,
        address beacon,
        bytes memory args,
        bytes32 salt
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x90), n))
            mstore(add(m, 0x70), 0x3d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3)
            mstore(add(m, 0x50), 0x527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b3513)
            mstore(add(m, 0x30), 0x60195155f3363d3d373d3d363d602036600436635c60da1b60e01b36)
            mstore(add(m, 0x14), beacon)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x57 = 0xffa8`.
            mstore(add(m, gt(n, 0xffa8)), add(0xfe6100573d8160233d3973, shl(56, n)))
            instance := create2(value, add(m, 0x16), add(n, 0x7a), salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Creates a deterministic ERC1967I beacon proxy with `args` and `salt`.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967IBeaconProxy(
        address beacon,
        bytes memory args,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        return createDeterministicERC1967IBeaconProxy(0, beacon, args, salt);
    }

    /// @dev Creates a deterministic ERC1967I beacon proxy with `args` and `salt`.
    /// Deposits `value` ETH during deployment.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967IBeaconProxy(
        uint256 value,
        address beacon,
        bytes memory args,
        bytes32 salt
    ) internal returns (bool alreadyDeployed, address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(args)
            pop(staticcall(gas(), 4, add(args, 0x20), n, add(m, 0x90), n))
            mstore(add(m, 0x70), 0x3d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3)
            mstore(add(m, 0x50), 0x527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b3513)
            mstore(add(m, 0x30), 0x60195155f3363d3d373d3d363d602036600436635c60da1b60e01b36)
            mstore(add(m, 0x14), beacon)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x57 = 0xffa8`.
            mstore(add(m, gt(n, 0xffa8)), add(0xfe6100573d8160233d3973, shl(56, n)))
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, keccak256(add(m, 0x16), add(n, 0x7a)))
            mstore(0x01, shl(96, address()))
            mstore(0x15, salt)
            instance := keccak256(0x00, 0x55)
            for {

            } 1 {

            } {
                if iszero(extcodesize(instance)) {
                    instance := create2(value, add(m, 0x16), add(n, 0x7a), salt)
                    if iszero(instance) {
                        mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                        revert(0x1c, 0x04)
                    }
                    break
                }
                alreadyDeployed := 1
                if iszero(value) {
                    break
                }
                if iszero(call(gas(), instance, value, codesize(), 0x00, codesize(), 0x00)) {
                    mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                    revert(0x1c, 0x04)
                }
                break
            }
            mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the initialization code of the ERC1967I beacon proxy with `args`.
    function initCodeERC1967IBeaconProxy(address beacon, bytes memory args) internal pure returns (bytes memory c) {
        /// @solidity memory-safe-assembly
        assembly {
            c := mload(0x40)
            let n := mload(args)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x57 = 0xffa8`.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0xffa8))
            for {
                let i := 0
            } lt(i, n) {
                i := add(i, 0x20)
            } {
                mstore(add(add(c, 0x9a), i), mload(add(add(args, 0x20), i)))
            }
            mstore(add(c, 0x7a), 0x3d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3)
            mstore(add(c, 0x5a), 0x527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b3513)
            mstore(add(c, 0x3a), 0x60195155f3363d3d373d3d363d602036600436635c60da1b60e01b36)
            mstore(add(c, 0x1e), beacon)
            mstore(add(c, 0x0a), add(0x6100573d8160233d3973, shl(56, n)))
            mstore(add(c, add(n, 0x9a)), 0)
            mstore(c, add(n, 0x7a)) // Store the length.
            mstore(0x40, add(c, add(n, 0xba))) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the ERC1967I beacon proxy with `args`.
    function initCodeHashERC1967IBeaconProxy(address beacon, bytes memory args) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let c := mload(0x40) // Cache the free memory pointer.
            let n := mload(args)
            // Do a out-of-gas revert if `n` is greater than `0xffff - 0x57 = 0xffa8`.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0xffa8))
            for {
                let i := 0
            } lt(i, n) {
                i := add(i, 0x20)
            } {
                mstore(add(add(c, 0x90), i), mload(add(add(args, 0x20), i)))
            }
            mstore(add(c, 0x70), 0x3d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3)
            mstore(add(c, 0x50), 0x527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b3513)
            mstore(add(c, 0x30), 0x60195155f3363d3d373d3d363d602036600436635c60da1b60e01b36)
            mstore(add(c, 0x14), beacon)
            mstore(c, add(0x6100573d8160233d3973, shl(56, n)))
            hash := keccak256(add(c, 0x16), add(n, 0x7a))
        }
    }

    /// @dev Returns the address of the ERC1967I beacon proxy, with  `args` and salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddressERC1967IBeaconProxy(
        address beacon,
        bytes memory args,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHashERC1967IBeaconProxy(beacon, args);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /// @dev Equivalent to `argsOnERC1967IBeaconProxy(instance, start, 2 ** 256 - 1)`.
    function argsOnERC1967IBeaconProxy(address instance) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            mstore(args, and(0xffffffffff, sub(extcodesize(instance), 0x57))) // Store the length.
            extcodecopy(instance, add(args, 0x20), 0x57, add(mload(args), 0x20))
            mstore(0x40, add(mload(args), add(args, 0x40))) // Allocate memory.
        }
    }

    /// @dev Equivalent to `argsOnERC1967IBeaconProxy(instance, start, 2 ** 256 - 1)`.
    function argsOnERC1967IBeaconProxy(address instance, uint256 start) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            let n := and(0xffffffffff, sub(extcodesize(instance), 0x57))
            let l := sub(n, and(0xffffff, mul(lt(start, n), start)))
            extcodecopy(instance, args, add(start, 0x37), add(l, 0x40))
            mstore(args, mul(sub(n, start), lt(start, n))) // Store the length.
            mstore(0x40, add(args, add(0x40, mload(args)))) // Allocate memory.
        }
    }

    /// @dev Returns a slice of the immutable arguments on `instance` from `start` to `end`.
    /// `start` and `end` will be clamped to the range `[0, args.length]`.
    /// The `instance` MUST be deployed via the ERC1967I beacon proxy with immutable args functions.
    /// Otherwise, the behavior is undefined.
    /// Out-of-gas reverts if `instance` does not have any code.
    function argsOnERC1967IBeaconProxy(
        address instance,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory args) {
        /// @solidity memory-safe-assembly
        assembly {
            args := mload(0x40)
            if iszero(lt(end, 0xffff)) {
                end := 0xffff
            }
            let d := mul(sub(end, start), lt(start, end))
            extcodecopy(instance, args, add(start, 0x37), add(d, 0x20))
            if iszero(and(0xff, mload(add(args, d)))) {
                let n := sub(extcodesize(instance), 0x57)
                returndatacopy(returndatasize(), returndatasize(), shr(40, n))
                d := mul(gt(n, start), sub(d, mul(gt(end, n), sub(end, n))))
            }
            mstore(args, d) // Store the length.
            mstore(add(add(args, 0x20), d), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(add(args, 0x40), d)) // Allocate memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      OTHER OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `address(0)` if the implementation address cannot be determined.
    function implementationOf(address instance) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {
                extcodecopy(instance, 0x00, 0x00, 0x57)
            } 1 {

            } {
                if mload(0x2d) {
                    // ERC1967I and ERC1967IBeaconProxy detection.
                    if or(
                        eq(keccak256(0x00, 0x52), ERC1967I_CODE_HASH),
                        eq(keccak256(0x00, 0x57), ERC1967I_BEACON_PROXY_CODE_HASH)
                    ) {
                        pop(staticcall(gas(), instance, 0x00, 0x01, 0x00, 0x20))
                        result := mload(0x0c)
                        break
                    }
                }
                // 0age clone detection.
                result := mload(0x0b)
                codecopy(0x0b, codesize(), 0x14) // Zeroize the 20 bytes for the address.
                if iszero(xor(keccak256(0x00, 0x2c), CLONE_CODE_HASH)) {
                    break
                }
                mstore(0x0b, result) // Restore the zeroized memory.
                // CWIA detection.
                result := mload(0x0a)
                codecopy(0x0a, codesize(), 0x14) // Zeroize the 20 bytes for the address.
                if iszero(xor(keccak256(0x00, 0x2d), CWIA_CODE_HASH)) {
                    break
                }
                mstore(0x0a, result) // Restore the zeroized memory.
                // PUSH0 clone detection.
                result := mload(0x09)
                codecopy(0x09, codesize(), 0x14) // Zeroize the 20 bytes for the address.
                result := shr(xor(keccak256(0x00, 0x2d), PUSH0_CLONE_CODE_HASH), result)
                break
            }
            result := shr(96, result)
            mstore(0x37, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the address when a contract with initialization code hash,
    /// `hash`, is deployed with `salt`, by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(
        bytes32 hash,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Requires that `salt` starts with either the zero address or `by`.
    function checkStartsWith(bytes32 salt, address by) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            // If the salt does not start with the zero address or `by`.
            if iszero(or(iszero(shr(96, salt)), eq(shr(96, shl(96, by)), shr(96, salt)))) {
                mstore(0x00, 0x0c4549ef) // `SaltDoesNotStartWith()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the `bytes32` at `offset` in `args`, without any bounds checks.
    /// To load an address, you can use `address(bytes20(argLoad(args, offset)))`.
    function argLoad(bytes memory args, uint256 offset) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(args, 0x20), offset))
        }
    }
}

// File solady/src/utils/LibBytes.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for byte related operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibBytes.sol)
library LibBytes {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Goated bytes storage struct that totally MOGs, no cap, fr.
    /// Uses less gas and bytecode than Solidity's native bytes storage. It's meta af.
    /// Packs length with the first 31 bytes if <255 bytes, so it’s mad tight.
    struct BytesStorage {
        bytes32 _spacer;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The constant returned when the `search` is not found in the bytes.
    uint256 internal constant NOT_FOUND = type(uint256).max;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  BYTE STORAGE OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sets the value of the bytes storage `$` to `s`.
    function set(BytesStorage storage $, bytes memory s) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(s)
            let packed := or(0xff, shl(8, n))
            for {
                let i := 0
            } 1 {

            } {
                if iszero(gt(n, 0xfe)) {
                    i := 0x1f
                    packed := or(n, shl(8, mload(add(s, i))))
                    if iszero(gt(n, i)) {
                        break
                    }
                }
                let o := add(s, 0x20)
                mstore(0x00, $.slot)
                for {
                    let p := keccak256(0x00, 0x20)
                } 1 {

                } {
                    sstore(add(p, shr(5, i)), mload(add(o, i)))
                    i := add(i, 0x20)
                    if iszero(lt(i, n)) {
                        break
                    }
                }
                break
            }
            sstore($.slot, packed)
        }
    }

    /// @dev Sets the value of the bytes storage `$` to `s`.
    function setCalldata(BytesStorage storage $, bytes calldata s) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let packed := or(0xff, shl(8, s.length))
            for {
                let i := 0
            } 1 {

            } {
                if iszero(gt(s.length, 0xfe)) {
                    i := 0x1f
                    packed := or(s.length, shl(8, shr(8, calldataload(s.offset))))
                    if iszero(gt(s.length, i)) {
                        break
                    }
                }
                mstore(0x00, $.slot)
                for {
                    let p := keccak256(0x00, 0x20)
                } 1 {

                } {
                    sstore(add(p, shr(5, i)), calldataload(add(s.offset, i)))
                    i := add(i, 0x20)
                    if iszero(lt(i, s.length)) {
                        break
                    }
                }
                break
            }
            sstore($.slot, packed)
        }
    }

    /// @dev Sets the value of the bytes storage `$` to the empty bytes.
    function clear(BytesStorage storage $) internal {
        delete $._spacer;
    }

    /// @dev Returns whether the value stored is `$` is the empty bytes "".
    function isEmpty(BytesStorage storage $) internal view returns (bool) {
        return uint256($._spacer) & 0xff == uint256(0);
    }

    /// @dev Returns the length of the value stored in `$`.
    function length(BytesStorage storage $) internal view returns (uint256 result) {
        result = uint256($._spacer);
        /// @solidity memory-safe-assembly
        assembly {
            let n := and(0xff, result)
            result := or(mul(shr(8, result), eq(0xff, n)), mul(n, iszero(eq(0xff, n))))
        }
    }

    /// @dev Returns the value stored in `$`.
    function get(BytesStorage storage $) internal view returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let o := add(result, 0x20)
            let packed := sload($.slot)
            let n := shr(8, packed)
            for {
                let i := 0
            } 1 {

            } {
                if iszero(eq(or(packed, 0xff), packed)) {
                    mstore(o, packed)
                    n := and(0xff, packed)
                    i := 0x1f
                    if iszero(gt(n, i)) {
                        break
                    }
                }
                mstore(0x00, $.slot)
                for {
                    let p := keccak256(0x00, 0x20)
                } 1 {

                } {
                    mstore(add(o, i), sload(add(p, shr(5, i))))
                    i := add(i, 0x20)
                    if iszero(lt(i, n)) {
                        break
                    }
                }
                break
            }
            mstore(result, n) // Store the length of the memory.
            mstore(add(o, n), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(add(o, n), 0x20)) // Allocate memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      BYTES OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `subject` all occurrences of `needle` replaced with `replacement`.
    function replace(
        bytes memory subject,
        bytes memory needle,
        bytes memory replacement
    ) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let needleLen := mload(needle)
            let replacementLen := mload(replacement)
            let d := sub(result, subject) // Memory difference.
            let i := add(subject, 0x20) // Subject bytes pointer.
            mstore(0x00, add(i, mload(subject))) // End of subject.
            if iszero(gt(needleLen, mload(subject))) {
                let subjectSearchEnd := add(sub(mload(0x00), needleLen), 1)
                let h := 0 // The hash of `needle`.
                if iszero(lt(needleLen, 0x20)) {
                    h := keccak256(add(needle, 0x20), needleLen)
                }
                let s := mload(add(needle, 0x20))
                for {
                    let m := shl(3, sub(0x20, and(needleLen, 0x1f)))
                } 1 {

                } {
                    let t := mload(i)
                    // Whether the first `needleLen % 32` bytes of `subject` and `needle` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(i, needleLen), h)) {
                                mstore(add(i, d), t)
                                i := add(i, 1)
                                if iszero(lt(i, subjectSearchEnd)) {
                                    break
                                }
                                continue
                            }
                        }
                        // Copy the `replacement` one word at a time.
                        for {
                            let j := 0
                        } 1 {

                        } {
                            mstore(add(add(i, d), j), mload(add(add(replacement, 0x20), j)))
                            j := add(j, 0x20)
                            if iszero(lt(j, replacementLen)) {
                                break
                            }
                        }
                        d := sub(add(d, replacementLen), needleLen)
                        if needleLen {
                            i := add(i, needleLen)
                            if iszero(lt(i, subjectSearchEnd)) {
                                break
                            }
                            continue
                        }
                    }
                    mstore(add(i, d), t)
                    i := add(i, 1)
                    if iszero(lt(i, subjectSearchEnd)) {
                        break
                    }
                }
            }
            let end := mload(0x00)
            let n := add(sub(d, add(result, 0x20)), end)
            // Copy the rest of the bytes one word at a time.
            for {

            } lt(i, end) {
                i := add(i, 0x20)
            } {
                mstore(add(i, d), mload(i))
            }
            let o := add(i, d)
            mstore(o, 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(o, 0x20)) // Allocate memory.
            mstore(result, n) // Store the length.
        }
    }

    /// @dev Returns the byte index of the first location of `needle` in `subject`,
    /// needleing from left to right, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.
    function indexOf(bytes memory subject, bytes memory needle, uint256 from) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := not(0) // Initialize to `NOT_FOUND`.
            for {
                let subjectLen := mload(subject)
            } 1 {

            } {
                if iszero(mload(needle)) {
                    result := from
                    if iszero(gt(from, subjectLen)) {
                        break
                    }
                    result := subjectLen
                    break
                }
                let needleLen := mload(needle)
                let subjectStart := add(subject, 0x20)

                subject := add(subjectStart, from)
                let end := add(sub(add(subjectStart, subjectLen), needleLen), 1)
                let m := shl(3, sub(0x20, and(needleLen, 0x1f)))
                let s := mload(add(needle, 0x20))

                if iszero(and(lt(subject, end), lt(from, subjectLen))) {
                    break
                }

                if iszero(lt(needleLen, 0x20)) {
                    for {
                        let h := keccak256(add(needle, 0x20), needleLen)
                    } 1 {

                    } {
                        if iszero(shr(m, xor(mload(subject), s))) {
                            if eq(keccak256(subject, needleLen), h) {
                                result := sub(subject, subjectStart)
                                break
                            }
                        }
                        subject := add(subject, 1)
                        if iszero(lt(subject, end)) {
                            break
                        }
                    }
                    break
                }
                for {

                } 1 {

                } {
                    if iszero(shr(m, xor(mload(subject), s))) {
                        result := sub(subject, subjectStart)
                        break
                    }
                    subject := add(subject, 1)
                    if iszero(lt(subject, end)) {
                        break
                    }
                }
                break
            }
        }
    }

    /// @dev Returns the byte index of the first location of `needle` in `subject`,
    /// needleing from left to right.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.
    function indexOf(bytes memory subject, bytes memory needle) internal pure returns (uint256) {
        return indexOf(subject, needle, 0);
    }

    /// @dev Returns the byte index of the first location of `needle` in `subject`,
    /// needleing from right to left, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.
    function lastIndexOf(
        bytes memory subject,
        bytes memory needle,
        uint256 from
    ) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {

            } 1 {

            } {
                result := not(0) // Initialize to `NOT_FOUND`.
                let needleLen := mload(needle)
                if gt(needleLen, mload(subject)) {
                    break
                }
                let w := result

                let fromMax := sub(mload(subject), needleLen)
                if iszero(gt(fromMax, from)) {
                    from := fromMax
                }

                let end := add(add(subject, 0x20), w)
                subject := add(add(subject, 0x20), from)
                if iszero(gt(subject, end)) {
                    break
                }
                // As this function is not too often used,
                // we shall simply use keccak256 for smaller bytecode size.
                for {
                    let h := keccak256(add(needle, 0x20), needleLen)
                } 1 {

                } {
                    if eq(keccak256(subject, needleLen), h) {
                        result := sub(subject, add(end, 1))
                        break
                    }
                    subject := add(subject, w) // `sub(subject, 1)`.
                    if iszero(gt(subject, end)) {
                        break
                    }
                }
                break
            }
        }
    }

    /// @dev Returns the byte index of the first location of `needle` in `subject`,
    /// needleing from right to left.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.
    function lastIndexOf(bytes memory subject, bytes memory needle) internal pure returns (uint256) {
        return lastIndexOf(subject, needle, type(uint256).max);
    }

    /// @dev Returns true if `needle` is found in `subject`, false otherwise.
    function contains(bytes memory subject, bytes memory needle) internal pure returns (bool) {
        return indexOf(subject, needle) != NOT_FOUND;
    }

    /// @dev Returns whether `subject` starts with `needle`.
    function startsWith(bytes memory subject, bytes memory needle) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(needle)
            // Just using keccak256 directly is actually cheaper.
            let t := eq(keccak256(add(subject, 0x20), n), keccak256(add(needle, 0x20), n))
            result := lt(gt(n, mload(subject)), t)
        }
    }

    /// @dev Returns whether `subject` ends with `needle`.
    function endsWith(bytes memory subject, bytes memory needle) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(needle)
            let notInRange := gt(n, mload(subject))
            // `subject + 0x20 + max(subject.length - needle.length, 0)`.
            let t := add(add(subject, 0x20), mul(iszero(notInRange), sub(mload(subject), n)))
            // Just using keccak256 directly is actually cheaper.
            result := gt(eq(keccak256(t, n), keccak256(add(needle, 0x20), n)), notInRange)
        }
    }

    /// @dev Returns `subject` repeated `times`.
    function repeat(bytes memory subject, uint256 times) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let l := mload(subject) // Subject length.
            if iszero(or(iszero(times), iszero(l))) {
                result := mload(0x40)
                subject := add(subject, 0x20)
                let o := add(result, 0x20)
                for {

                } 1 {

                } {
                    // Copy the `subject` one word at a time.
                    for {
                        let j := 0
                    } 1 {

                    } {
                        mstore(add(o, j), mload(add(subject, j)))
                        j := add(j, 0x20)
                        if iszero(lt(j, l)) {
                            break
                        }
                    }
                    o := add(o, l)
                    times := sub(times, 1)
                    if iszero(times) {
                        break
                    }
                }
                mstore(o, 0) // Zeroize the slot after the bytes.
                mstore(0x40, add(o, 0x20)) // Allocate memory.
                mstore(result, sub(o, add(result, 0x20))) // Store the length.
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function slice(bytes memory subject, uint256 start, uint256 end) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let l := mload(subject) // Subject length.
            if iszero(gt(l, end)) {
                end := l
            }
            if iszero(gt(l, start)) {
                start := l
            }
            if lt(start, end) {
                result := mload(0x40)
                let n := sub(end, start)
                let i := add(subject, start)
                let w := not(0x1f)
                // Copy the `subject` one word at a time, backwards.
                for {
                    let j := and(add(n, 0x1f), w)
                } 1 {

                } {
                    mstore(add(result, j), mload(add(i, j)))
                    j := add(j, w) // `sub(j, 0x20)`.
                    if iszero(j) {
                        break
                    }
                }
                let o := add(add(result, 0x20), n)
                mstore(o, 0) // Zeroize the slot after the bytes.
                mstore(0x40, add(o, 0x20)) // Allocate memory.
                mstore(result, n) // Store the length.
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to the end of the bytes.
    /// `start` is a byte offset.
    function slice(bytes memory subject, uint256 start) internal pure returns (bytes memory result) {
        result = slice(subject, start, type(uint256).max);
    }

    /// @dev Returns a copy of `subject` sliced from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets. Faster than Solidity's native slicing.
    function sliceCalldata(
        bytes calldata subject,
        uint256 start,
        uint256 end
    ) internal pure returns (bytes calldata result) {
        /// @solidity memory-safe-assembly
        assembly {
            end := xor(end, mul(xor(end, subject.length), lt(subject.length, end)))
            start := xor(start, mul(xor(start, subject.length), lt(subject.length, start)))
            result.offset := add(subject.offset, start)
            result.length := mul(lt(start, end), sub(end, start))
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to the end of the bytes.
    /// `start` is a byte offset. Faster than Solidity's native slicing.
    function sliceCalldata(bytes calldata subject, uint256 start) internal pure returns (bytes calldata result) {
        /// @solidity memory-safe-assembly
        assembly {
            start := xor(start, mul(xor(start, subject.length), lt(subject.length, start)))
            result.offset := add(subject.offset, start)
            result.length := mul(lt(start, subject.length), sub(subject.length, start))
        }
    }

    /// @dev Reduces the size of `subject` to `n`.
    /// If `n` is greater than the size of `subject`, this will be a no-op.
    function truncate(bytes memory subject, uint256 n) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := subject
            mstore(mul(lt(n, mload(result)), result), n)
        }
    }

    /// @dev Returns a copy of `subject`, with the length reduced to `n`.
    /// If `n` is greater than the size of `subject`, this will be a no-op.
    function truncatedCalldata(bytes calldata subject, uint256 n) internal pure returns (bytes calldata result) {
        /// @solidity memory-safe-assembly
        assembly {
            result.offset := subject.offset
            result.length := xor(n, mul(xor(n, subject.length), lt(subject.length, n)))
        }
    }

    /// @dev Returns all the indices of `needle` in `subject`.
    /// The indices are byte offsets.
    function indicesOf(bytes memory subject, bytes memory needle) internal pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let searchLen := mload(needle)
            if iszero(gt(searchLen, mload(subject))) {
                result := mload(0x40)
                let i := add(subject, 0x20)
                let o := add(result, 0x20)
                let subjectSearchEnd := add(sub(add(i, mload(subject)), searchLen), 1)
                let h := 0 // The hash of `needle`.
                if iszero(lt(searchLen, 0x20)) {
                    h := keccak256(add(needle, 0x20), searchLen)
                }
                let s := mload(add(needle, 0x20))
                for {
                    let m := shl(3, sub(0x20, and(searchLen, 0x1f)))
                } 1 {

                } {
                    let t := mload(i)
                    // Whether the first `searchLen % 32` bytes of `subject` and `needle` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(i, searchLen), h)) {
                                i := add(i, 1)
                                if iszero(lt(i, subjectSearchEnd)) {
                                    break
                                }
                                continue
                            }
                        }
                        mstore(o, sub(i, add(subject, 0x20))) // Append to `result`.
                        o := add(o, 0x20)
                        i := add(i, searchLen) // Advance `i` by `searchLen`.
                        if searchLen {
                            if iszero(lt(i, subjectSearchEnd)) {
                                break
                            }
                            continue
                        }
                    }
                    i := add(i, 1)
                    if iszero(lt(i, subjectSearchEnd)) {
                        break
                    }
                }
                mstore(result, shr(5, sub(o, add(result, 0x20)))) // Store the length of `result`.
                // Allocate memory for result.
                // We allocate one more word, so this array can be recycled for {split}.
                mstore(0x40, add(o, 0x20))
            }
        }
    }

    /// @dev Returns an arrays of bytess based on the `delimiter` inside of the `subject` bytes.
    function split(bytes memory subject, bytes memory delimiter) internal pure returns (bytes[] memory result) {
        uint256[] memory indices = indicesOf(subject, delimiter);
        /// @solidity memory-safe-assembly
        assembly {
            let w := not(0x1f)
            let indexPtr := add(indices, 0x20)
            let indicesEnd := add(indexPtr, shl(5, add(mload(indices), 1)))
            mstore(add(indicesEnd, w), mload(subject))
            mstore(indices, add(mload(indices), 1))
            for {
                let prevIndex := 0
            } 1 {

            } {
                let index := mload(indexPtr)
                mstore(indexPtr, 0x60)
                if iszero(eq(index, prevIndex)) {
                    let element := mload(0x40)
                    let l := sub(index, prevIndex)
                    mstore(element, l) // Store the length of the element.
                    // Copy the `subject` one word at a time, backwards.
                    for {
                        let o := and(add(l, 0x1f), w)
                    } 1 {

                    } {
                        mstore(add(element, o), mload(add(add(subject, prevIndex), o)))
                        o := add(o, w) // `sub(o, 0x20)`.
                        if iszero(o) {
                            break
                        }
                    }
                    mstore(add(add(element, 0x20), l), 0) // Zeroize the slot after the bytes.
                    // Allocate memory for the length and the bytes, rounded up to a multiple of 32.
                    mstore(0x40, add(element, and(add(l, 0x3f), w)))
                    mstore(indexPtr, element) // Store the `element` into the array.
                }
                prevIndex := add(index, mload(delimiter))
                indexPtr := add(indexPtr, 0x20)
                if iszero(lt(indexPtr, indicesEnd)) {
                    break
                }
            }
            result := indices
            if iszero(mload(delimiter)) {
                result := add(indices, 0x20)
                mstore(result, sub(mload(indices), 2))
            }
        }
    }

    /// @dev Returns a concatenated bytes of `a` and `b`.
    /// Cheaper than `bytes.concat()` and does not de-align the free memory pointer.
    function concat(bytes memory a, bytes memory b) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let w := not(0x1f)
            let aLen := mload(a)
            // Copy `a` one word at a time, backwards.
            for {
                let o := and(add(aLen, 0x20), w)
            } 1 {

            } {
                mstore(add(result, o), mload(add(a, o)))
                o := add(o, w) // `sub(o, 0x20)`.
                if iszero(o) {
                    break
                }
            }
            let bLen := mload(b)
            let output := add(result, aLen)
            // Copy `b` one word at a time, backwards.
            for {
                let o := and(add(bLen, 0x20), w)
            } 1 {

            } {
                mstore(add(output, o), mload(add(b, o)))
                o := add(o, w) // `sub(o, 0x20)`.
                if iszero(o) {
                    break
                }
            }
            let totalLen := add(aLen, bLen)
            let last := add(add(result, 0x20), totalLen)
            mstore(last, 0) // Zeroize the slot after the bytes.
            mstore(result, totalLen) // Store the length.
            mstore(0x40, add(last, 0x20)) // Allocate memory.
        }
    }

    /// @dev Returns whether `a` equals `b`.
    function eq(bytes memory a, bytes memory b) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := eq(keccak256(add(a, 0x20), mload(a)), keccak256(add(b, 0x20), mload(b)))
        }
    }

    /// @dev Returns whether `a` equals `b`, where `b` is a null-terminated small bytes.
    function eqs(bytes memory a, bytes32 b) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            // These should be evaluated on compile time, as far as possible.
            let m := not(shl(7, div(not(iszero(b)), 255))) // `0x7f7f ...`.
            let x := not(or(m, or(b, add(m, and(b, m)))))
            let r := shl(7, iszero(iszero(shr(128, x))))
            r := or(r, shl(6, iszero(iszero(shr(64, shr(r, x))))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            // forgefmt: disable-next-item
            result := gt(
                eq(mload(a), add(iszero(x), xor(31, shr(3, r)))),
                xor(shr(add(8, r), b), shr(add(8, r), mload(add(a, 0x20))))
            )
        }
    }

    /// @dev Returns 0 if `a == b`, -1 if `a < b`, +1 if `a > b`.
    /// If `a` == b[:a.length]`, and `a.length < b.length`, returns -1.
    function cmp(bytes memory a, bytes memory b) internal pure returns (int256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let aLen := mload(a)
            let bLen := mload(b)
            let n := and(xor(aLen, mul(xor(aLen, bLen), lt(bLen, aLen))), not(0x1f))
            if n {
                for {
                    let i := 0x20
                } 1 {

                } {
                    let x := mload(add(a, i))
                    let y := mload(add(b, i))
                    if iszero(or(xor(x, y), eq(i, n))) {
                        i := add(i, 0x20)
                        continue
                    }
                    result := sub(gt(x, y), lt(x, y))
                    break
                }
            }
            // forgefmt: disable-next-item
            if iszero(result) {
                let l := 0x201f1e1d1c1b1a191817161514131211100f0e0d0c0b0a090807060504030201
                let x := and(mload(add(add(a, 0x20), n)), shl(shl(3, byte(sub(aLen, n), l)), not(0)))
                let y := and(mload(add(add(b, 0x20), n)), shl(shl(3, byte(sub(bLen, n), l)), not(0)))
                result := sub(gt(x, y), lt(x, y))
                if iszero(result) {
                    result := sub(gt(aLen, bLen), lt(aLen, bLen))
                }
            }
        }
    }

    /// @dev Directly returns `a` without copying.
    function directReturn(bytes memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            // Assumes that the bytes does not start from the scratch space.
            let retStart := sub(a, 0x20)
            let retUnpaddedSize := add(mload(a), 0x40)
            // Right pad with zeroes. Just in case the bytes is produced
            // by a method that doesn't zero right pad.
            mstore(add(retStart, retUnpaddedSize), 0)
            mstore(retStart, 0x20) // Store the return offset.
            // End the transaction, returning the bytes.
            return(retStart, and(not(0x1f), add(0x1f, retUnpaddedSize)))
        }
    }

    /// @dev Directly returns `a` with minimal copying.
    function directReturn(bytes[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(a) // `a.length`.
            let o := add(a, 0x20) // Start of elements in `a`.
            let u := a // Highest memory slot.
            let w := not(0x1f)
            for {
                let i := 0
            } iszero(eq(i, n)) {
                i := add(i, 1)
            } {
                let c := add(o, shl(5, i)) // Location of pointer to `a[i]`.
                let s := mload(c) // `a[i]`.
                let l := mload(s) // `a[i].length`.
                let r := and(l, 0x1f) // `a[i].length % 32`.
                let z := add(0x20, and(l, w)) // Offset of last word in `a[i]` from `s`.
                // If `s` comes before `o`, or `s` is not zero right padded.
                if iszero(lt(lt(s, o), or(iszero(r), iszero(shl(shl(3, r), mload(add(s, z))))))) {
                    let m := mload(0x40)
                    mstore(m, l) // Copy `a[i].length`.
                    for {

                    } 1 {

                    } {
                        mstore(add(m, z), mload(add(s, z))) // Copy `a[i]`, backwards.
                        z := add(z, w) // `sub(z, 0x20)`.
                        if iszero(z) {
                            break
                        }
                    }
                    let e := add(add(m, 0x20), l)
                    mstore(e, 0) // Zeroize the slot after the copied bytes.
                    mstore(0x40, add(e, 0x20)) // Allocate memory.
                    s := m
                }
                mstore(c, sub(s, o)) // Convert to calldata offset.
                let t := add(l, add(s, 0x20))
                if iszero(lt(t, u)) {
                    u := t
                }
            }
            let retStart := add(a, w) // Assumes `a` doesn't start from scratch space.
            mstore(retStart, 0x20) // Store the return offset.
            return(retStart, add(0x40, sub(u, retStart))) // End the transaction.
        }
    }

    /// @dev Returns the word at `offset`, without any bounds checks.
    function load(bytes memory a, uint256 offset) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(a, 0x20), offset))
        }
    }

    /// @dev Returns the word at `offset`, without any bounds checks.
    function loadCalldata(bytes calldata a, uint256 offset) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := calldataload(add(a.offset, offset))
        }
    }

    /// @dev Returns a slice representing a static struct in the calldata. Performs bounds checks.
    function staticStructInCalldata(bytes calldata a, uint256 offset) internal pure returns (bytes calldata result) {
        /// @solidity memory-safe-assembly
        assembly {
            let l := sub(a.length, 0x20)
            result.offset := add(a.offset, offset)
            result.length := sub(a.length, offset)
            if or(shr(64, or(l, a.offset)), gt(offset, l)) {
                revert(l, 0x00)
            }
        }
    }

    /// @dev Returns a slice representing a dynamic struct in the calldata. Performs bounds checks.
    function dynamicStructInCalldata(bytes calldata a, uint256 offset) internal pure returns (bytes calldata result) {
        /// @solidity memory-safe-assembly
        assembly {
            let l := sub(a.length, 0x20)
            let s := calldataload(add(a.offset, offset)) // Relative offset of `result` from `a.offset`.
            result.offset := add(a.offset, s)
            result.length := sub(a.length, s)
            if or(shr(64, or(s, or(l, a.offset))), gt(offset, l)) {
                revert(l, 0x00)
            }
        }
    }

    /// @dev Returns bytes in calldata. Performs bounds checks.
    function bytesInCalldata(bytes calldata a, uint256 offset) internal pure returns (bytes calldata result) {
        /// @solidity memory-safe-assembly
        assembly {
            let l := sub(a.length, 0x20)
            let s := calldataload(add(a.offset, offset)) // Relative offset of `result` from `a.offset`.
            result.offset := add(add(a.offset, s), 0x20)
            result.length := calldataload(add(a.offset, s))
            // forgefmt: disable-next-item
            if or(shr(64, or(result.length, or(s, or(l, a.offset)))), or(gt(add(s, result.length), l), gt(offset, l))) {
                revert(l, 0x00)
            }
        }
    }

    /// @dev Returns empty calldata bytes. For silencing the compiler.
    function emptyCalldata() internal pure returns (bytes calldata result) {
        /// @solidity memory-safe-assembly
        assembly {
            result.length := 0
        }
    }
}

// File solady/src/utils/LibString.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for converting numbers into strings and other string operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibString.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
///
/// @dev Note:
/// For performance and bytecode compactness, most of the string operations are restricted to
/// byte strings (7-bit ASCII), except where otherwise specified.
/// Usage of byte string operations on charsets with runes spanning two or more bytes
/// can lead to undefined behavior.
library LibString {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Goated string storage struct that totally MOGs, no cap, fr.
    /// Uses less gas and bytecode than Solidity's native string storage. It's meta af.
    /// Packs length with the first 31 bytes if <255 bytes, so it’s mad tight.
    struct StringStorage {
        bytes32 _spacer;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The length of the output is too small to contain all the hex digits.
    error HexLengthInsufficient();

    /// @dev The length of the string is more than 32 bytes.
    error TooBigForSmallString();

    /// @dev The input string must be a 7-bit ASCII.
    error StringNot7BitASCII();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The constant returned when the `search` is not found in the string.
    uint256 internal constant NOT_FOUND = type(uint256).max;

    /// @dev Lookup for '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'.
    uint128 internal constant ALPHANUMERIC_7_BIT_ASCII = 0x7fffffe07fffffe03ff000000000000;

    /// @dev Lookup for 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'.
    uint128 internal constant LETTERS_7_BIT_ASCII = 0x7fffffe07fffffe0000000000000000;

    /// @dev Lookup for 'abcdefghijklmnopqrstuvwxyz'.
    uint128 internal constant LOWERCASE_7_BIT_ASCII = 0x7fffffe000000000000000000000000;

    /// @dev Lookup for 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
    uint128 internal constant UPPERCASE_7_BIT_ASCII = 0x7fffffe0000000000000000;

    /// @dev Lookup for '0123456789'.
    uint128 internal constant DIGITS_7_BIT_ASCII = 0x3ff000000000000;

    /// @dev Lookup for '0123456789abcdefABCDEF'.
    uint128 internal constant HEXDIGITS_7_BIT_ASCII = 0x7e0000007e03ff000000000000;

    /// @dev Lookup for '01234567'.
    uint128 internal constant OCTDIGITS_7_BIT_ASCII = 0xff000000000000;

    /// @dev Lookup for '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~ \t\n\r\x0b\x0c'.
    uint128 internal constant PRINTABLE_7_BIT_ASCII = 0x7fffffffffffffffffffffff00003e00;

    /// @dev Lookup for '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'.
    uint128 internal constant PUNCTUATION_7_BIT_ASCII = 0x78000001f8000001fc00fffe00000000;

    /// @dev Lookup for ' \t\n\r\x0b\x0c'.
    uint128 internal constant WHITESPACE_7_BIT_ASCII = 0x100003e00;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 STRING STORAGE OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sets the value of the string storage `$` to `s`.
    function set(StringStorage storage $, string memory s) internal {
        LibBytes.set(bytesStorage($), bytes(s));
    }

    /// @dev Sets the value of the string storage `$` to `s`.
    function setCalldata(StringStorage storage $, string calldata s) internal {
        LibBytes.setCalldata(bytesStorage($), bytes(s));
    }

    /// @dev Sets the value of the string storage `$` to the empty string.
    function clear(StringStorage storage $) internal {
        delete $._spacer;
    }

    /// @dev Returns whether the value stored is `$` is the empty string "".
    function isEmpty(StringStorage storage $) internal view returns (bool) {
        return uint256($._spacer) & 0xff == uint256(0);
    }

    /// @dev Returns the length of the value stored in `$`.
    function length(StringStorage storage $) internal view returns (uint256) {
        return LibBytes.length(bytesStorage($));
    }

    /// @dev Returns the value stored in `$`.
    function get(StringStorage storage $) internal view returns (string memory) {
        return string(LibBytes.get(bytesStorage($)));
    }

    /// @dev Helper to cast `$` to a `BytesStorage`.
    function bytesStorage(StringStorage storage $) internal pure returns (LibBytes.BytesStorage storage casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted.slot := $.slot
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     DECIMAL OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits.
            result := add(mload(0x40), 0x80)
            mstore(0x40, add(result, 0x20)) // Allocate memory.
            mstore(result, 0) // Zeroize the slot after the string.

            let end := result // Cache the end of the memory to calculate the length later.
            let w := not(0) // Tsk.
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for {
                let temp := value
            } 1 {

            } {
                result := add(result, w) // `sub(result, 1)`.
                // Store the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(result, add(48, mod(temp, 10)))
                temp := div(temp, 10) // Keep dividing `temp` until zero.
                if iszero(temp) {
                    break
                }
            }
            let n := sub(end, result)
            result := sub(result, 0x20) // Move the pointer 32 bytes back to make room for the length.
            mstore(result, n) // Store the length.
        }
    }

    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(int256 value) internal pure returns (string memory result) {
        if (value >= 0) return toString(uint256(value));
        unchecked {
            result = toString(~uint256(value) + 1);
        }
        /// @solidity memory-safe-assembly
        assembly {
            // We still have some spare memory space on the left,
            // as we have allocated 3 words (96 bytes) for up to 78 digits.
            let n := mload(result) // Load the string length.
            mstore(result, 0x2d) // Store the '-' character.
            result := sub(result, 1) // Move back the string pointer by a byte.
            mstore(result, add(n, 1)) // Update the string length.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   HEXADECIMAL OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the hexadecimal representation of `value`,
    /// left-padded to an input length of `byteCount` bytes.
    /// The output is prefixed with "0x" encoded using 2 hexadecimal digits per byte,
    /// giving a total length of `byteCount * 2 + 2` bytes.
    /// Reverts if `byteCount` is too small for the output to contain all the digits.
    function toHexString(uint256 value, uint256 byteCount) internal pure returns (string memory result) {
        result = toHexStringNoPrefix(value, byteCount);
        /// @solidity memory-safe-assembly
        assembly {
            let n := add(mload(result), 2) // Compute the length.
            mstore(result, 0x3078) // Store the "0x" prefix.
            result := sub(result, 2) // Move the pointer.
            mstore(result, n) // Store the length.
        }
    }

    /// @dev Returns the hexadecimal representation of `value`,
    /// left-padded to an input length of `byteCount` bytes.
    /// The output is not prefixed with "0x" and is encoded using 2 hexadecimal digits per byte,
    /// giving a total length of `byteCount * 2` bytes.
    /// Reverts if `byteCount` is too small for the output to contain all the digits.
    function toHexStringNoPrefix(uint256 value, uint256 byteCount) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            // We need 0x20 bytes for the trailing zeros padding, `byteCount * 2` bytes
            // for the digits, 0x02 bytes for the prefix, and 0x20 bytes for the length.
            // We add 0x20 to the total and round down to a multiple of 0x20.
            // (0x20 + 0x20 + 0x02 + 0x20) = 0x62.
            result := add(mload(0x40), and(add(shl(1, byteCount), 0x42), not(0x1f)))
            mstore(0x40, add(result, 0x20)) // Allocate memory.
            mstore(result, 0) // Zeroize the slot after the string.

            let end := result // Cache the end to calculate the length later.
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let start := sub(result, add(byteCount, byteCount))
            let w := not(1) // Tsk.
            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for {

            } 1 {

            } {
                result := add(result, w) // `sub(result, 2)`.
                mstore8(add(result, 1), mload(and(temp, 15)))
                mstore8(result, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                if iszero(xor(result, start)) {
                    break
                }
            }
            if temp {
                mstore(0x00, 0x2194895a) // `HexLengthInsufficient()`.
                revert(0x1c, 0x04)
            }
            let n := sub(end, result)
            result := sub(result, 0x20)
            mstore(result, n) // Store the length.
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    /// As address are 20 bytes long, the output will left-padded to have
    /// a length of `20 * 2 + 2` bytes.
    function toHexString(uint256 value) internal pure returns (string memory result) {
        result = toHexStringNoPrefix(value);
        /// @solidity memory-safe-assembly
        assembly {
            let n := add(mload(result), 2) // Compute the length.
            mstore(result, 0x3078) // Store the "0x" prefix.
            result := sub(result, 2) // Move the pointer.
            mstore(result, n) // Store the length.
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x".
    /// The output excludes leading "0" from the `toHexString` output.
    /// `0x00: "0x0", 0x01: "0x1", 0x12: "0x12", 0x123: "0x123"`.
    function toMinimalHexString(uint256 value) internal pure returns (string memory result) {
        result = toHexStringNoPrefix(value);
        /// @solidity memory-safe-assembly
        assembly {
            let o := eq(byte(0, mload(add(result, 0x20))), 0x30) // Whether leading zero is present.
            let n := add(mload(result), 2) // Compute the length.
            mstore(add(result, o), 0x3078) // Store the "0x" prefix, accounting for leading zero.
            result := sub(add(result, o), 2) // Move the pointer, accounting for leading zero.
            mstore(result, sub(n, o)) // Store the length, accounting for leading zero.
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output excludes leading "0" from the `toHexStringNoPrefix` output.
    /// `0x00: "0", 0x01: "1", 0x12: "12", 0x123: "123"`.
    function toMinimalHexStringNoPrefix(uint256 value) internal pure returns (string memory result) {
        result = toHexStringNoPrefix(value);
        /// @solidity memory-safe-assembly
        assembly {
            let o := eq(byte(0, mload(add(result, 0x20))), 0x30) // Whether leading zero is present.
            let n := mload(result) // Get the length.
            result := add(result, o) // Move the pointer, accounting for leading zero.
            mstore(result, sub(n, o)) // Store the length, accounting for leading zero.
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is encoded using 2 hexadecimal digits per byte.
    /// As address are 20 bytes long, the output will left-padded to have
    /// a length of `20 * 2` bytes.
    function toHexStringNoPrefix(uint256 value) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            // We need 0x20 bytes for the trailing zeros padding, 0x20 bytes for the length,
            // 0x02 bytes for the prefix, and 0x40 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x20 + 0x02 + 0x40) is 0xa0.
            result := add(mload(0x40), 0x80)
            mstore(0x40, add(result, 0x20)) // Allocate memory.
            mstore(result, 0) // Zeroize the slot after the string.

            let end := result // Cache the end to calculate the length later.
            mstore(0x0f, 0x30313233343536373839616263646566) // Store the "0123456789abcdef" lookup.

            let w := not(1) // Tsk.
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for {
                let temp := value
            } 1 {

            } {
                result := add(result, w) // `sub(result, 2)`.
                mstore8(add(result, 1), mload(and(temp, 15)))
                mstore8(result, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                if iszero(temp) {
                    break
                }
            }
            let n := sub(end, result)
            result := sub(result, 0x20)
            mstore(result, n) // Store the length.
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x", encoded using 2 hexadecimal digits per byte,
    /// and the alphabets are capitalized conditionally according to
    /// https://eips.ethereum.org/EIPS/eip-55
    function toHexStringChecksummed(address value) internal pure returns (string memory result) {
        result = toHexString(value);
        /// @solidity memory-safe-assembly
        assembly {
            let mask := shl(6, div(not(0), 255)) // `0b010000000100000000 ...`
            let o := add(result, 0x22)
            let hashed := and(keccak256(o, 40), mul(34, mask)) // `0b10001000 ... `
            let t := shl(240, 136) // `0b10001000 << 240`
            for {
                let i := 0
            } 1 {

            } {
                mstore(add(i, i), mul(t, byte(i, hashed)))
                i := add(i, 1)
                if eq(i, 20) {
                    break
                }
            }
            mstore(o, xor(mload(o), shr(1, and(mload(0x00), and(mload(o), mask)))))
            o := add(o, 0x20)
            mstore(o, xor(mload(o), shr(1, and(mload(0x20), and(mload(o), mask)))))
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    function toHexString(address value) internal pure returns (string memory result) {
        result = toHexStringNoPrefix(value);
        /// @solidity memory-safe-assembly
        assembly {
            let n := add(mload(result), 2) // Compute the length.
            mstore(result, 0x3078) // Store the "0x" prefix.
            result := sub(result, 2) // Move the pointer.
            mstore(result, n) // Store the length.
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is encoded using 2 hexadecimal digits per byte.
    function toHexStringNoPrefix(address value) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            // Allocate memory.
            // We need 0x20 bytes for the trailing zeros padding, 0x20 bytes for the length,
            // 0x02 bytes for the prefix, and 0x28 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x20 + 0x02 + 0x28) is 0x80.
            mstore(0x40, add(result, 0x80))
            mstore(0x0f, 0x30313233343536373839616263646566) // Store the "0123456789abcdef" lookup.

            result := add(result, 2)
            mstore(result, 40) // Store the length.
            let o := add(result, 0x20)
            mstore(add(o, 40), 0) // Zeroize the slot after the string.
            value := shl(96, value)
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for {
                let i := 0
            } 1 {

            } {
                let p := add(o, add(i, i))
                let temp := byte(i, value)
                mstore8(add(p, 1), mload(and(temp, 15)))
                mstore8(p, mload(shr(4, temp)))
                i := add(i, 1)
                if eq(i, 20) {
                    break
                }
            }
        }
    }

    /// @dev Returns the hex encoded string from the raw bytes.
    /// The output is encoded using 2 hexadecimal digits per byte.
    function toHexString(bytes memory raw) internal pure returns (string memory result) {
        result = toHexStringNoPrefix(raw);
        /// @solidity memory-safe-assembly
        assembly {
            let n := add(mload(result), 2) // Compute the length.
            mstore(result, 0x3078) // Store the "0x" prefix.
            result := sub(result, 2) // Move the pointer.
            mstore(result, n) // Store the length.
        }
    }

    /// @dev Returns the hex encoded string from the raw bytes.
    /// The output is encoded using 2 hexadecimal digits per byte.
    function toHexStringNoPrefix(bytes memory raw) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(raw)
            result := add(mload(0x40), 2) // Skip 2 bytes for the optional prefix.
            mstore(result, add(n, n)) // Store the length of the output.

            mstore(0x0f, 0x30313233343536373839616263646566) // Store the "0123456789abcdef" lookup.
            let o := add(result, 0x20)
            let end := add(raw, n)
            for {

            } iszero(eq(raw, end)) {

            } {
                raw := add(raw, 1)
                mstore8(add(o, 1), mload(and(mload(raw), 15)))
                mstore8(o, mload(and(shr(4, mload(raw)), 15)))
                o := add(o, 2)
            }
            mstore(o, 0) // Zeroize the slot after the string.
            mstore(0x40, add(o, 0x20)) // Allocate memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   RUNE STRING OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the number of UTF characters in the string.
    function runeCount(string memory s) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(s) {
                mstore(0x00, div(not(0), 255))
                mstore(0x20, 0x0202020202020202020202020202020202020202020202020303030304040506)
                let o := add(s, 0x20)
                let end := add(o, mload(s))
                for {
                    result := 1
                } 1 {
                    result := add(result, 1)
                } {
                    o := add(o, byte(0, mload(shr(250, mload(o)))))
                    if iszero(lt(o, end)) {
                        break
                    }
                }
            }
        }
    }

    /// @dev Returns if this string is a 7-bit ASCII string.
    /// (i.e. all characters codes are in [0..127])
    function is7BitASCII(string memory s) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let mask := shl(7, div(not(0), 255))
            let n := mload(s)
            if n {
                let o := add(s, 0x20)
                let end := add(o, n)
                let last := mload(end)
                mstore(end, 0)
                for {

                } 1 {

                } {
                    if and(mask, mload(o)) {
                        result := 0
                        break
                    }
                    o := add(o, 0x20)
                    if iszero(lt(o, end)) {
                        break
                    }
                }
                mstore(end, last)
            }
        }
    }

    /// @dev Returns if this string is a 7-bit ASCII string,
    /// AND all characters are in the `allowed` lookup.
    /// Note: If `s` is empty, returns true regardless of `allowed`.
    function is7BitASCII(string memory s, uint128 allowed) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            if mload(s) {
                let allowed_ := shr(128, shl(128, allowed))
                let o := add(s, 0x20)
                for {
                    let end := add(o, mload(s))
                } 1 {

                } {
                    result := and(result, shr(byte(0, mload(o)), allowed_))
                    o := add(o, 1)
                    if iszero(and(result, lt(o, end))) {
                        break
                    }
                }
            }
        }
    }

    /// @dev Converts the bytes in the 7-bit ASCII string `s` to
    /// an allowed lookup for use in `is7BitASCII(s, allowed)`.
    /// To save runtime gas, you can cache the result in an immutable variable.
    function to7BitASCIIAllowedLookup(string memory s) internal pure returns (uint128 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(s) {
                let o := add(s, 0x20)
                for {
                    let end := add(o, mload(s))
                } 1 {

                } {
                    result := or(result, shl(byte(0, mload(o)), 1))
                    o := add(o, 1)
                    if iszero(lt(o, end)) {
                        break
                    }
                }
                if shr(128, result) {
                    mstore(0x00, 0xc9807e0d) // `StringNot7BitASCII()`.
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   BYTE STRING OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // For performance and bytecode compactness, byte string operations are restricted
    // to 7-bit ASCII strings. All offsets are byte offsets, not UTF character offsets.
    // Usage of byte string operations on charsets with runes spanning two or more bytes
    // can lead to undefined behavior.

    /// @dev Returns `subject` all occurrences of `needle` replaced with `replacement`.
    function replace(
        string memory subject,
        string memory needle,
        string memory replacement
    ) internal pure returns (string memory) {
        return string(LibBytes.replace(bytes(subject), bytes(needle), bytes(replacement)));
    }

    /// @dev Returns the byte index of the first location of `needle` in `subject`,
    /// needleing from left to right, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.
    function indexOf(string memory subject, string memory needle, uint256 from) internal pure returns (uint256) {
        return LibBytes.indexOf(bytes(subject), bytes(needle), from);
    }

    /// @dev Returns the byte index of the first location of `needle` in `subject`,
    /// needleing from left to right.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.
    function indexOf(string memory subject, string memory needle) internal pure returns (uint256) {
        return LibBytes.indexOf(bytes(subject), bytes(needle), 0);
    }

    /// @dev Returns the byte index of the first location of `needle` in `subject`,
    /// needleing from right to left, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.
    function lastIndexOf(string memory subject, string memory needle, uint256 from) internal pure returns (uint256) {
        return LibBytes.lastIndexOf(bytes(subject), bytes(needle), from);
    }

    /// @dev Returns the byte index of the first location of `needle` in `subject`,
    /// needleing from right to left.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.
    function lastIndexOf(string memory subject, string memory needle) internal pure returns (uint256) {
        return LibBytes.lastIndexOf(bytes(subject), bytes(needle), type(uint256).max);
    }

    /// @dev Returns true if `needle` is found in `subject`, false otherwise.
    function contains(string memory subject, string memory needle) internal pure returns (bool) {
        return LibBytes.contains(bytes(subject), bytes(needle));
    }

    /// @dev Returns whether `subject` starts with `needle`.
    function startsWith(string memory subject, string memory needle) internal pure returns (bool) {
        return LibBytes.startsWith(bytes(subject), bytes(needle));
    }

    /// @dev Returns whether `subject` ends with `needle`.
    function endsWith(string memory subject, string memory needle) internal pure returns (bool) {
        return LibBytes.endsWith(bytes(subject), bytes(needle));
    }

    /// @dev Returns `subject` repeated `times`.
    function repeat(string memory subject, uint256 times) internal pure returns (string memory) {
        return string(LibBytes.repeat(bytes(subject), times));
    }

    /// @dev Returns a copy of `subject` sliced from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function slice(string memory subject, uint256 start, uint256 end) internal pure returns (string memory) {
        return string(LibBytes.slice(bytes(subject), start, end));
    }

    /// @dev Returns a copy of `subject` sliced from `start` to the end of the string.
    /// `start` is a byte offset.
    function slice(string memory subject, uint256 start) internal pure returns (string memory) {
        return string(LibBytes.slice(bytes(subject), start, type(uint256).max));
    }

    /// @dev Returns all the indices of `needle` in `subject`.
    /// The indices are byte offsets.
    function indicesOf(string memory subject, string memory needle) internal pure returns (uint256[] memory) {
        return LibBytes.indicesOf(bytes(subject), bytes(needle));
    }

    /// @dev Returns an arrays of strings based on the `delimiter` inside of the `subject` string.
    function split(string memory subject, string memory delimiter) internal pure returns (string[] memory result) {
        bytes[] memory a = LibBytes.split(bytes(subject), bytes(delimiter));
        /// @solidity memory-safe-assembly
        assembly {
            result := a
        }
    }

    /// @dev Returns a concatenated string of `a` and `b`.
    /// Cheaper than `string.concat()` and does not de-align the free memory pointer.
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(LibBytes.concat(bytes(a), bytes(b)));
    }

    /// @dev Returns a copy of the string in either lowercase or UPPERCASE.
    /// WARNING! This function is only compatible with 7-bit ASCII strings.
    function toCase(string memory subject, bool toUpper) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(subject)
            if n {
                result := mload(0x40)
                let o := add(result, 0x20)
                let d := sub(subject, result)
                let flags := shl(add(70, shl(5, toUpper)), 0x3ffffff)
                for {
                    let end := add(o, n)
                } 1 {

                } {
                    let b := byte(0, mload(add(d, o)))
                    mstore8(o, xor(and(shr(b, flags), 0x20), b))
                    o := add(o, 1)
                    if eq(o, end) {
                        break
                    }
                }
                mstore(result, n) // Store the length.
                mstore(o, 0) // Zeroize the slot after the string.
                mstore(0x40, add(o, 0x20)) // Allocate memory.
            }
        }
    }

    /// @dev Returns a string from a small bytes32 string.
    /// `s` must be null-terminated, or behavior will be undefined.
    function fromSmallString(bytes32 s) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let n := 0
            for {

            } byte(n, s) {
                n := add(n, 1)
            } {

            } // Scan for '\0'.
            mstore(result, n) // Store the length.
            let o := add(result, 0x20)
            mstore(o, s) // Store the bytes of the string.
            mstore(add(o, n), 0) // Zeroize the slot after the string.
            mstore(0x40, add(result, 0x40)) // Allocate memory.
        }
    }

    /// @dev Returns the small string, with all bytes after the first null byte zeroized.
    function normalizeSmallString(bytes32 s) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {

            } byte(result, s) {
                result := add(result, 1)
            } {

            } // Scan for '\0'.
            mstore(0x00, s)
            mstore(result, 0x00)
            result := mload(0x00)
        }
    }

    /// @dev Returns the string as a normalized null-terminated small string.
    function toSmallString(string memory s) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(s)
            if iszero(lt(result, 33)) {
                mstore(0x00, 0xec92f9a3) // `TooBigForSmallString()`.
                revert(0x1c, 0x04)
            }
            result := shl(shl(3, sub(32, result)), mload(add(s, result)))
        }
    }

    /// @dev Returns a lowercased copy of the string.
    /// WARNING! This function is only compatible with 7-bit ASCII strings.
    function lower(string memory subject) internal pure returns (string memory result) {
        result = toCase(subject, false);
    }

    /// @dev Returns an UPPERCASED copy of the string.
    /// WARNING! This function is only compatible with 7-bit ASCII strings.
    function upper(string memory subject) internal pure returns (string memory result) {
        result = toCase(subject, true);
    }

    /// @dev Escapes the string to be used within HTML tags.
    function escapeHTML(string memory s) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let end := add(s, mload(s))
            let o := add(result, 0x20)
            // Store the bytes of the packed offsets and strides into the scratch space.
            // `packed = (stride << 5) | offset`. Max offset is 20. Max stride is 6.
            mstore(0x1f, 0x900094)
            mstore(0x08, 0xc0000000a6ab)
            // Store "&quot;&amp;&#39;&lt;&gt;" into the scratch space.
            mstore(0x00, shl(64, 0x2671756f743b26616d703b262333393b266c743b2667743b))
            for {

            } iszero(eq(s, end)) {

            } {
                s := add(s, 1)
                let c := and(mload(s), 0xff)
                // Not in `["\"","'","&","<",">"]`.
                if iszero(and(shl(c, 1), 0x500000c400000000)) {
                    mstore8(o, c)
                    o := add(o, 1)
                    continue
                }
                let t := shr(248, mload(c))
                mstore(o, mload(and(t, 0x1f)))
                o := add(o, shr(5, t))
            }
            mstore(o, 0) // Zeroize the slot after the string.
            mstore(result, sub(o, add(result, 0x20))) // Store the length.
            mstore(0x40, add(o, 0x20)) // Allocate memory.
        }
    }

    /// @dev Escapes the string to be used within double-quotes in a JSON.
    /// If `addDoubleQuotes` is true, the result will be enclosed in double-quotes.
    function escapeJSON(string memory s, bool addDoubleQuotes) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let o := add(result, 0x20)
            if addDoubleQuotes {
                mstore8(o, 34)
                o := add(1, o)
            }
            // Store "\\u0000" in scratch space.
            // Store "0123456789abcdef" in scratch space.
            // Also, store `{0x08:"b", 0x09:"t", 0x0a:"n", 0x0c:"f", 0x0d:"r"}`.
            // into the scratch space.
            mstore(0x15, 0x5c75303030303031323334353637383961626364656662746e006672)
            // Bitmask for detecting `["\"","\\"]`.
            let e := or(shl(0x22, 1), shl(0x5c, 1))
            for {
                let end := add(s, mload(s))
            } iszero(eq(s, end)) {

            } {
                s := add(s, 1)
                let c := and(mload(s), 0xff)
                if iszero(lt(c, 0x20)) {
                    if iszero(and(shl(c, 1), e)) {
                        // Not in `["\"","\\"]`.
                        mstore8(o, c)
                        o := add(o, 1)
                        continue
                    }
                    mstore8(o, 0x5c) // "\\".
                    mstore8(add(o, 1), c)
                    o := add(o, 2)
                    continue
                }
                if iszero(and(shl(c, 1), 0x3700)) {
                    // Not in `["\b","\t","\n","\f","\d"]`.
                    mstore8(0x1d, mload(shr(4, c))) // Hex value.
                    mstore8(0x1e, mload(and(c, 15))) // Hex value.
                    mstore(o, mload(0x19)) // "\\u00XX".
                    o := add(o, 6)
                    continue
                }
                mstore8(o, 0x5c) // "\\".
                mstore8(add(o, 1), mload(add(c, 8)))
                o := add(o, 2)
            }
            if addDoubleQuotes {
                mstore8(o, 34)
                o := add(1, o)
            }
            mstore(o, 0) // Zeroize the slot after the string.
            mstore(result, sub(o, add(result, 0x20))) // Store the length.
            mstore(0x40, add(o, 0x20)) // Allocate memory.
        }
    }

    /// @dev Escapes the string to be used within double-quotes in a JSON.
    function escapeJSON(string memory s) internal pure returns (string memory result) {
        result = escapeJSON(s, false);
    }

    /// @dev Encodes `s` so that it can be safely used in a URI,
    /// just like `encodeURIComponent` in JavaScript.
    /// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
    /// See: https://datatracker.ietf.org/doc/html/rfc2396
    /// See: https://datatracker.ietf.org/doc/html/rfc3986
    function encodeURIComponent(string memory s) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            // Store "0123456789ABCDEF" in scratch space.
            // Uppercased to be consistent with JavaScript's implementation.
            mstore(0x0f, 0x30313233343536373839414243444546)
            let o := add(result, 0x20)
            for {
                let end := add(s, mload(s))
            } iszero(eq(s, end)) {

            } {
                s := add(s, 1)
                let c := and(mload(s), 0xff)
                // If not in `[0-9A-Z-a-z-_.!~*'()]`.
                if iszero(and(1, shr(c, 0x47fffffe87fffffe03ff678200000000))) {
                    mstore8(o, 0x25) // '%'.
                    mstore8(add(o, 1), mload(and(shr(4, c), 15)))
                    mstore8(add(o, 2), mload(and(c, 15)))
                    o := add(o, 3)
                    continue
                }
                mstore8(o, c)
                o := add(o, 1)
            }
            mstore(result, sub(o, add(result, 0x20))) // Store the length.
            mstore(o, 0) // Zeroize the slot after the string.
            mstore(0x40, add(o, 0x20)) // Allocate memory.
        }
    }

    /// @dev Returns whether `a` equals `b`.
    function eq(string memory a, string memory b) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := eq(keccak256(add(a, 0x20), mload(a)), keccak256(add(b, 0x20), mload(b)))
        }
    }

    /// @dev Returns whether `a` equals `b`, where `b` is a null-terminated small string.
    function eqs(string memory a, bytes32 b) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            // These should be evaluated on compile time, as far as possible.
            let m := not(shl(7, div(not(iszero(b)), 255))) // `0x7f7f ...`.
            let x := not(or(m, or(b, add(m, and(b, m)))))
            let r := shl(7, iszero(iszero(shr(128, x))))
            r := or(r, shl(6, iszero(iszero(shr(64, shr(r, x))))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            // forgefmt: disable-next-item
            result := gt(
                eq(mload(a), add(iszero(x), xor(31, shr(3, r)))),
                xor(shr(add(8, r), b), shr(add(8, r), mload(add(a, 0x20))))
            )
        }
    }

    /// @dev Returns 0 if `a == b`, -1 if `a < b`, +1 if `a > b`.
    /// If `a` == b[:a.length]`, and `a.length < b.length`, returns -1.
    function cmp(string memory a, string memory b) internal pure returns (int256) {
        return LibBytes.cmp(bytes(a), bytes(b));
    }

    /// @dev Packs a single string with its length into a single word.
    /// Returns `bytes32(0)` if the length is zero or greater than 31.
    function packOne(string memory a) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // We don't need to zero right pad the string,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes.
                mload(add(a, 0x1f)),
                // `length != 0 && length < 32`. Abuses underflow.
                // Assumes that the length is valid and within the block gas limit.
                lt(sub(mload(a), 1), 0x1f)
            )
        }
    }

    /// @dev Unpacks a string packed using {packOne}.
    /// Returns the empty string if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packOne}, the output behavior is undefined.
    function unpackOne(bytes32 packed) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40) // Grab the free memory pointer.
            mstore(0x40, add(result, 0x40)) // Allocate 2 words (1 for the length, 1 for the bytes).
            mstore(result, 0) // Zeroize the length slot.
            mstore(add(result, 0x1f), packed) // Store the length and bytes.
            mstore(add(add(result, 0x20), mload(result)), 0) // Right pad with zeroes.
        }
    }

    /// @dev Packs two strings with their lengths into a single word.
    /// Returns `bytes32(0)` if combined length is zero or greater than 30.
    function packTwo(string memory a, string memory b) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let aLen := mload(a)
            // We don't need to zero right pad the strings,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                or(
                    // Load the length and the bytes of `a` and `b`.
                    shl(shl(3, sub(0x1f, aLen)), mload(add(a, aLen))),
                    mload(sub(add(b, 0x1e), aLen))
                ),
                // `totalLen != 0 && totalLen < 31`. Abuses underflow.
                // Assumes that the lengths are valid and within the block gas limit.
                lt(sub(add(aLen, mload(b)), 1), 0x1e)
            )
        }
    }

    /// @dev Unpacks strings packed using {packTwo}.
    /// Returns the empty strings if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packTwo}, the output behavior is undefined.
    function unpackTwo(bytes32 packed) internal pure returns (string memory resultA, string memory resultB) {
        /// @solidity memory-safe-assembly
        assembly {
            resultA := mload(0x40) // Grab the free memory pointer.
            resultB := add(resultA, 0x40)
            // Allocate 2 words for each string (1 for the length, 1 for the byte). Total 4 words.
            mstore(0x40, add(resultB, 0x40))
            // Zeroize the length slots.
            mstore(resultA, 0)
            mstore(resultB, 0)
            // Store the lengths and bytes.
            mstore(add(resultA, 0x1f), packed)
            mstore(add(resultB, 0x1f), mload(add(add(resultA, 0x20), mload(resultA))))
            // Right pad with zeroes.
            mstore(add(add(resultA, 0x20), mload(resultA)), 0)
            mstore(add(add(resultB, 0x20), mload(resultB)), 0)
        }
    }

    /// @dev Directly returns `a` without copying.
    function directReturn(string memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            // Assumes that the string does not start from the scratch space.
            let retStart := sub(a, 0x20)
            let retUnpaddedSize := add(mload(a), 0x40)
            // Right pad with zeroes. Just in case the string is produced
            // by a method that doesn't zero right pad.
            mstore(add(retStart, retUnpaddedSize), 0)
            mstore(retStart, 0x20) // Store the return offset.
            // End the transaction, returning the string.
            return(retStart, and(not(0x1f), add(0x1f, retUnpaddedSize)))
        }
    }
}

// File solady/src/utils/SSTORE2.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SSTORE2.sol)
/// @author Saw-mon-and-Natalie (https://github.com/Saw-mon-and-Natalie)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
/// @author Modified from SSTORE3 (https://github.com/Philogy/sstore3)
library SSTORE2 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The proxy initialization code.
    uint256 private constant _CREATE3_PROXY_INITCODE = 0x67363d3d37363d34f03d5260086018f3;

    /// @dev Hash of the `_CREATE3_PROXY_INITCODE`.
    /// Equivalent to `keccak256(abi.encodePacked(hex"67363d3d37363d34f03d5260086018f3"))`.
    bytes32 internal constant CREATE3_PROXY_INITCODE_HASH =
        0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the storage contract.
    error DeploymentFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         WRITE LOGIC                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
    function write(bytes memory data) internal returns (address pointer) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(data) // Let `l` be `n + 1`. +1 as we prefix a STOP opcode.
            /**
             * ---------------------------------------------------+
             * Opcode | Mnemonic       | Stack     | Memory       |
             * ---------------------------------------------------|
             * 61 l   | PUSH2 l        | l         |              |
             * 80     | DUP1           | l l       |              |
             * 60 0xa | PUSH1 0xa      | 0xa l l   |              |
             * 3D     | RETURNDATASIZE | 0 0xa l l |              |
             * 39     | CODECOPY       | l         | [0..l): code |
             * 3D     | RETURNDATASIZE | 0 l       | [0..l): code |
             * F3     | RETURN         |           | [0..l): code |
             * 00     | STOP           |           |              |
             * ---------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called.
             * Also PUSH2 is used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            // Do a out-of-gas revert if `n + 1` is more than 2 bytes.
            mstore(add(data, gt(n, 0xfffe)), add(0xfe61000180600a3d393df300, shl(0x40, n)))
            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 0x15), add(n, 0xb))
            if iszero(pointer) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(data, n) // Restore the length of `data`.
        }
    }

    /// @dev Writes `data` into the bytecode of a storage contract with `salt`
    /// and returns its normal CREATE2 deterministic address.
    function writeCounterfactual(bytes memory data, bytes32 salt) internal returns (address pointer) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(data)
            // Do a out-of-gas revert if `n + 1` is more than 2 bytes.
            mstore(add(data, gt(n, 0xfffe)), add(0xfe61000180600a3d393df300, shl(0x40, n)))
            // Deploy a new contract with the generated creation code.
            pointer := create2(0, add(data, 0x15), add(n, 0xb), salt)
            if iszero(pointer) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(data, n) // Restore the length of `data`.
        }
    }

    /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
    /// This uses the so-called "CREATE3" workflow,
    /// which means that `pointer` is agnostic to `data, and only depends on `salt`.
    function writeDeterministic(bytes memory data, bytes32 salt) internal returns (address pointer) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(data)
            mstore(0x00, _CREATE3_PROXY_INITCODE) // Store the `_PROXY_INITCODE`.
            let proxy := create2(0, 0x10, 0x10, salt)
            if iszero(proxy) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x14, proxy) // Store the proxy's address.
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            mstore8(0x34, 0x01) // Nonce of the proxy contract (1).
            pointer := keccak256(0x1e, 0x17)

            // Do a out-of-gas revert if `n + 1` is more than 2 bytes.
            mstore(add(data, gt(n, 0xfffe)), add(0xfe61000180600a3d393df300, shl(0x40, n)))
            if iszero(
                mul(
                    // The arguments of `mul` are evaluated last to first.
                    extcodesize(pointer),
                    call(gas(), proxy, 0, add(data, 0x15), add(n, 0xb), codesize(), 0x00)
                )
            ) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(data, n) // Restore the length of `data`.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    ADDRESS CALCULATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the initialization code hash of the storage contract for `data`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(bytes memory data) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(data)
            // Do a out-of-gas revert if `n + 1` is more than 2 bytes.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0xfffe))
            mstore(data, add(0x61000180600a3d393df300, shl(0x40, n)))
            hash := keccak256(add(data, 0x15), add(n, 0xb))
            mstore(data, n) // Restore the length of `data`.
        }
    }

    /// @dev Equivalent to `predictCounterfactualAddress(data, salt, address(this))`
    function predictCounterfactualAddress(bytes memory data, bytes32 salt) internal view returns (address pointer) {
        pointer = predictCounterfactualAddress(data, salt, address(this));
    }

    /// @dev Returns the CREATE2 address of the storage contract for `data`
    /// deployed with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictCounterfactualAddress(
        bytes memory data,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHash(data);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }

    /// @dev Equivalent to `predictDeterministicAddress(salt, address(this))`.
    function predictDeterministicAddress(bytes32 salt) internal view returns (address pointer) {
        pointer = predictDeterministicAddress(salt, address(this));
    }

    /// @dev Returns the "CREATE3" deterministic address for `salt` with `deployer`.
    function predictDeterministicAddress(bytes32 salt, address deployer) internal pure returns (address pointer) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, deployer) // Store `deployer`.
            mstore8(0x0b, 0xff) // Store the prefix.
            mstore(0x20, salt) // Store the salt.
            mstore(0x40, CREATE3_PROXY_INITCODE_HASH) // Store the bytecode hash.

            mstore(0x14, keccak256(0x0b, 0x55)) // Store the proxy's address.
            mstore(0x40, m) // Restore the free memory pointer.
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            mstore8(0x34, 0x01) // Nonce of the proxy contract (1).
            pointer := keccak256(0x1e, 0x17)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         READ LOGIC                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `read(pointer, 0, 2 ** 256 - 1)`.
    function read(address pointer) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            data := mload(0x40)
            let n := and(0xffffffffff, sub(extcodesize(pointer), 0x01))
            extcodecopy(pointer, add(data, 0x1f), 0x00, add(n, 0x21))
            mstore(data, n) // Store the length.
            mstore(0x40, add(n, add(data, 0x40))) // Allocate memory.
        }
    }

    /// @dev Equivalent to `read(pointer, start, 2 ** 256 - 1)`.
    function read(address pointer, uint256 start) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            data := mload(0x40)
            let n := and(0xffffffffff, sub(extcodesize(pointer), 0x01))
            let l := sub(n, and(0xffffff, mul(lt(start, n), start)))
            extcodecopy(pointer, add(data, 0x1f), start, add(l, 0x21))
            mstore(data, mul(sub(n, start), lt(start, n))) // Store the length.
            mstore(0x40, add(data, add(0x40, mload(data)))) // Allocate memory.
        }
    }

    /// @dev Returns a slice of the data on `pointer` from `start` to `end`.
    /// `start` and `end` will be clamped to the range `[0, args.length]`.
    /// The `pointer` MUST be deployed via the SSTORE2 write functions.
    /// Otherwise, the behavior is undefined.
    /// Out-of-gas reverts if `pointer` does not have any code.
    function read(address pointer, uint256 start, uint256 end) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            data := mload(0x40)
            if iszero(lt(end, 0xffff)) {
                end := 0xffff
            }
            let d := mul(sub(end, start), lt(start, end))
            extcodecopy(pointer, add(data, 0x1f), start, add(d, 0x01))
            if iszero(and(0xff, mload(add(data, d)))) {
                let n := sub(extcodesize(pointer), 0x01)
                returndatacopy(returndatasize(), returndatasize(), shr(40, n))
                d := mul(gt(n, start), sub(d, mul(gt(end, n), sub(end, n))))
            }
            mstore(data, d) // Store the length.
            mstore(add(add(data, 0x20), d), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(add(data, 0x40), d)) // Allocate memory.
        }
    }
}

// File contracts/src/PropositionMarket/PropositionMarketPool.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.23;

contract PropositionMarketPool is IPropositionMarketPool, ReentrancyGuard, Initializable, UUPSUpgradeable {
    using Price for *;
    using LibClone for *;
    using LibString for *;
    using FixedPointMathLib for *;

    uint256 public totalPlatformFee;
    bool public paused;
    uint256 public tvl;

    modifier onlyFactory() {
        if (getFactoryAddress() != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert EnforcedPause();
        _;
    }

    modifier timeCheck(uint256 expireTimestamp) {
        if (expireTimestamp < block.timestamp) revert TimeoutProhibition();
        _;
    }

    modifier tokenAmountCheck(uint256 tokenAmount) {
        if (tokenAmount == 0) revert ZeroQuantityError();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        // any logic you want at deployment time, eg registering with factory
        __UUPSUpgradeable_init();
    }

    function buy(
        IPropositionMarketToken token,
        uint256 tokenAmount,
        uint256 usdtProvided,
        uint256 minTokenReceived,
        uint256 expireTimestamp
    ) external nonReentrant whenNotPaused timeCheck(expireTimestamp) tokenAmountCheck(usdtProvided) {
        // calculate price and amount
        (uint256 tokenSupply, uint256 supplyOther) = _getSupplies(address(token));

        uint256 tokenPrice = tokenSupply.getExecutionPrice(supplyOther, int256(tokenAmount));
        uint256 usdtAmount = tokenPrice.mulWad(tokenAmount);
        uint256 usdtNetAmount = usdtAmount.divWad(1 ether.rawSub(getPlatformFee()));

        // check usdt provided
        if (
            usdtNetAmount > usdtProvided ||
            (usdtProvided.rawSub(usdtNetAmount) > (usdtProvided / Price.DEFAULT_APPROXIMATION_PRECISION))
        ) {
            // Recalculate token amount and execution price by approximation
            (tokenAmount, tokenPrice) = Price.approximateExecutionPrice(tokenSupply, supplyOther, usdtAmount);

            // check slippage
            if (tokenAmount < minTokenReceived) revert SlippageFailed(tokenAmount, minTokenReceived);

            // Update values with new token amount
            usdtAmount = tokenPrice.mulWad(tokenAmount);
            usdtNetAmount = usdtAmount.divWad(1 ether.rawSub(getPlatformFee()));
        }

        // calculate platform fee
        totalPlatformFee += usdtNetAmount.rawSub(usdtAmount);

        // transfer usdt from sender
        if (!getPayTokenAddress().transferFrom(msg.sender, address(this), usdtNetAmount)) revert PaymentFailed();

        // update tvl
        tvl += usdtAmount;

        // mint and transfer token to sender
        if (tokenAmount < minTokenReceived) revert SlippageFailed(tokenAmount, minTokenReceived);

        _mintAndTransfer(token, tokenAmount);

        // emit event
        IPropositionMarketFactory(getFactoryAddress()).emitEventTrade(
            address(token),
            msg.sender,
            int256(tokenAmount),
            tokenPrice
        );
        emit Swap(msg.sender, usdtNetAmount, tokenAmount, address(getPayTokenAddress()), address(token));
    }

    function sell(
        IPropositionMarketToken token,
        uint256 tokenAmount,
        uint256 minUsdtReceived,
        uint256 expireTimestamp
    ) external nonReentrant whenNotPaused timeCheck(expireTimestamp) tokenAmountCheck(tokenAmount) {
        // calculate price and amount
        (uint256 tokenSupply, uint256 supplyOther) = _getSupplies(address(token));
        uint256 tokenPrice = tokenSupply.getExecutionPrice(supplyOther, -int256(tokenAmount));
        uint256 usdtAmount = tokenPrice.mulWad(tokenAmount);

        // calculate platform fee
        uint256 platformFee = usdtAmount.mulWad(getPlatformFee());
        totalPlatformFee += platformFee;
        uint256 usdtNetAmount = usdtAmount.rawSub(platformFee);

        // check minimum received amount
        if (usdtNetAmount < minUsdtReceived) revert SlippageFailed(usdtNetAmount, minUsdtReceived);

        // transfer token from sender and burn it
        token.burn(msg.sender, tokenAmount);

        // update tvl
        tvl -= tokenAmount;

        // transfer usdt to sender
        if (!getPayTokenAddress().transfer(msg.sender, usdtNetAmount)) revert PaymentFailed();

        // emit event
        IPropositionMarketFactory(getFactoryAddress()).emitEventTrade(
            address(token),
            msg.sender,
            -int256(tokenAmount),
            tokenPrice
        );
        emit Swap(msg.sender, usdtNetAmount, tokenAmount, address(getPayTokenAddress()), address(token));
    }

    function collectPlatformFee(address receiver) external onlyFactory {
        if (totalPlatformFee == 0) revert InsufficientBalance();
        uint256 oldTotalPlatformFee = totalPlatformFee;

        totalPlatformFee = 0;

        if (!getPayTokenAddress().transfer(receiver, oldTotalPlatformFee)) revert PaymentFailed();
    }

    function pausedPool() external onlyFactory {
        if (paused) revert EnforcedPause();
        emit Paused(paused = !paused);
    }

    function getOptionListLength() public view returns (uint256 length) {
        bytes memory data = address(this).argsOnERC1967(0, 8);
        assembly {
            length := shr(192, mload(add(data, 32))) // 取低8字节
        }
        return length;
    }

    function getOptionList() public view returns (address[] memory) {
        unchecked {
            uint256 length = getOptionListLength();
            address dataPointer = _bytesToAddressExact(address(this).argsOnERC1967(8, 28));
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));

            address[] memory sliced = new address[](length);
            for (uint256 i = 0; i < length; ++i) {
                sliced[i] = fullList[i];
            }

            return sliced;
        }
    }

    function getFactoryAddress() public view returns (address) {
        unchecked {
            address dataPointer = _bytesToAddressExact(address(this).argsOnERC1967(8, 28));
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));
            return fullList[fullList.length - 3];
        }
    }

    function getManagerAddress() public view returns (address) {
        unchecked {
            address dataPointer = _bytesToAddressExact(address(this).argsOnERC1967(8, 28));
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));
            return fullList[fullList.length - 2];
        }
    }

    function getPayTokenAddress() public view returns (IERC20) {
        unchecked {
            address dataPointer = _bytesToAddressExact(address(this).argsOnERC1967(8, 28));
            address[] memory fullList = abi.decode(SSTORE2.read(dataPointer), (address[]));
            return IERC20(fullList[fullList.length - 1]);
        }
    }

    function getPlatformFee() public view returns (uint256) {
        return IPropositionMarketFactory(getFactoryAddress()).getPlatformFee();
    }

    function getSpotPrice(address token) public view returns (uint256) {
        (uint256 supply, uint256 supplyOther) = _getSupplies(token);
        return Price.getSpotPrice(supply, supplyOther);
    }

    function getExecutionPrice(address token, int256 amountChanged) public view returns (uint256) {
        (uint256 supply, uint256 supplyOther) = _getSupplies(token);
        return Price.getExecutionPrice(supply, supplyOther, amountChanged);
    }

    function getApproximatePrice(
        address token,
        uint256 usdtAmount,
        uint256 precision,
        uint256 maxIteration
    ) public view returns (uint256 tokenAmount, uint256 avgPrice) {
        (uint256 supply, uint256 supplyOther) = _getSupplies(token);
        (tokenAmount, avgPrice) = Price.approximateExecutionPrice(
            supply,
            supplyOther,
            usdtAmount,
            precision,
            maxIteration
        );
    }

    function getPoolTitle() public view returns (string memory) {
        unchecked {
            return _bytesToBytes32(address(this).argsOnERC1967(28, 60)).fromSmallString();
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyFactory {}

    function _mintAndTransfer(IPropositionMarketToken token, uint256 tokenAmount) internal {
        token.mint(msg.sender, tokenAmount);
        // if (!token.transfer(msg.sender, tokenAmount)) revert PaymentFailed();
    }

    function _getSupplies(address token) internal view returns (uint256 supply, uint256 supplyOther) {
        supply = IERC20(token).totalSupply();
        address[] memory optionList = getOptionList();
        bool find = false;

        for (uint256 i = 0; i < optionList.length; ++i) {
            if (optionList[i] != token) {
                supplyOther += IERC20(optionList[i]).totalSupply();
            } else {
                find = true;
            }
        }

        if (!find) revert InvalidToken();
    }

    function _bytesToAddressExact(bytes memory data) internal pure returns (address result) {
        assembly {
            result := shr(96, mload(add(data, 32))) // shift right 96 bits = 12 bytes = keep low 20 bytes
        }
    }

    function _bytesToBytes32(bytes memory data) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(data, 32))
        }
    }
}
