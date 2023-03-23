// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin-contracts-upgradeable/contracts/utils/Create2Upgradeable.sol";
import "../openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../openzeppelin-contracts/contracts/access/Ownable.sol";

import "./external/lib/MinimalProxyLibrary.sol";
import "./vaults/CounterfactualVault.sol";

import "forge-std/console.sol";

/// @notice Counterfactually instantiates a wallet at an address unique to an ERC721 token.  The address for an ERC721 token can be computed and later
/// plundered by transferring token balances to the ERC721 owner.
contract CounterfactualVaultController is Ownable {
    /// @notice A structure to define arbitrary contract calls
    struct VaultCall {
        uint256 vaultId;
        CounterfactualVault.Call[] call;
    }

    CounterfactualVault public counterfactualWalletInstance;

    bytes32 internal immutable _counterfactualVaultBytecodeHash;
    bytes internal _counterfactualVaultBytecode;

    /// @notice Emitted when a wallet is executed
    event Executed(uint256 indexed vaultId, address indexed operator);

    /// @dev Creates a new CounterfactualVault instance and an associated minimal proxy.
    constructor(address owner) Ownable() {
        counterfactualWalletInstance = new CounterfactualVault();
        counterfactualWalletInstance.initialize(); // do we need this? does it have to be a new CounterfactualVault each time?
        // or we can hardcode this
        // or deploy one CounterfactualVault instance before and pass in the constructor

        _transferOwnership(owner);

        _counterfactualVaultBytecode = MinimalProxyLibrary.minimalProxy(
            address(counterfactualWalletInstance)
        );
        _counterfactualVaultBytecodeHash = keccak256(
            _counterfactualVaultBytecode
        );
    }

    /// @dev The wallet will be counterfactually created and calls executed
    /// @param vaultCalls The array of call structs that define that the vaultId target, amount of ether, and data.
    function executeVaultCalls(
        VaultCall[] calldata vaultCalls
    ) external onlyOwner returns (bytes[][] memory) {
        bytes[][] memory result = new bytes[][](vaultCalls.length);
        address _owner = owner();

        for (uint256 i = 0; i < vaultCalls.length; i++) {
            result[i] = _createCFVault(_owner, vaultCalls[i].vaultId)
                .executeCalls(vaultCalls[i].call);

            emit Executed(vaultCalls[i].vaultId, msg.sender);
        }

        return result;
    }

    /// @notice Computes the Counterfactual Vault addresseses for given vaultIds.
    /// @dev The contract will not exist yet, so the address will have no code.
    /// @param vaultIds The vaultIds (vault nonce)
    function computeAddress(
        uint256[] calldata vaultIds
    ) external view returns (address[] memory) {
        address[] memory vaults = new address[](vaultIds.length);
        for (uint256 i = 0; i < vaultIds.length; i++) {
            vaults[i] = Create2Upgradeable.computeAddress(
                _salt(owner(), vaultIds[i]),
                _counterfactualVaultBytecodeHash
            );
        }

        return vaults;
    }

    /// @notice Creates a CounterfactualVault for the given owners address.
    /// @param owner The owners address
    /// @param vaultId The counterfactual vault id
    function _createCFVault(
        address owner,
        uint256 vaultId
    ) internal returns (CounterfactualVault) {
        CounterfactualVault counterfactualVault = CounterfactualVault(
            Create2Upgradeable.deploy(
                0,
                _salt(owner, vaultId),
                _counterfactualVaultBytecode
            )
        );
        counterfactualVault.initialize();
        return counterfactualVault;
    }

    /// @notice Computes the CREATE2 salt for the given owner and vaultId.
    /// @param owner The owners address
    /// @param vaultId The vaultId
    function _salt(
        address owner,
        uint256 vaultId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, vaultId));
    }
}
