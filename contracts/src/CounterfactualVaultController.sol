// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin-contracts-upgradeable/contracts/utils/Create2Upgradeable.sol";
import "../openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../openzeppelin-contracts/contracts/access/Ownable.sol";

import "./external/lib/MinimalProxyLibrary.sol";
import "./CounterfactualVault.sol";

/// @notice Counterfactually instantiates a wallet at an address unique to an ERC721 token.  The address for an ERC721 token can be computed and later
/// plundered by transferring token balances to the ERC721 owner.
contract CounterfactualVaultController is Ownable {
    CounterfactualVault public counterfactualWalletInstance;

    bytes32 internal immutable _counterfactualVaultBytecodeHash;
    bytes internal _counterfactualVaultBytecode;

    /// @notice Emitted when a wallet is executed
    event Executed(
        address indexed erc721,
        uint256 indexed tokenId,
        address indexed operator
    );

    /// @notice Constructs a new controller.
    /// @dev Creates a new CounterfactualVault instance and an associated minimal proxy.
    constructor(address owner) Ownable() {
        counterfactualWalletInstance = new CounterfactualVault();
        counterfactualWalletInstance.initialize();

        _transferOwnership(owner);

        _counterfactualVaultBytecode = MinimalProxyLibrary.minimalProxy(
            address(counterfactualWalletInstance)
        );
        _counterfactualVaultBytecodeHash = keccak256(
            _counterfactualVaultBytecode
        );
    }

    /// @notice Allows owner to transfer all given tokens in a counterfactual wallet to a destination address
    /// @notice Allows the owner of an ERC721 to execute abitrary calls on behalf of the associated counterfactual wallet.
    /// @dev The wallet will be counterfactually created, calls executed, then the contract destroyed.
    /// @param erc721 The ERC721 address
    /// @param tokenId The ERC721 token id
    /// @param calls The array of call structs that define that target, amount of ether, and data.
    /// @return The array of call return values.
    function executeCalls(
        address erc721,
        uint256 tokenId,
        CounterfactualVault.Call[] calldata calls
    ) external onlyOwner returns (bytes[] memory) {
        CounterfactualVault counterfactualVault = _createCFVault(
            erc721,
            tokenId
        );
        (erc721, tokenId);
        bytes[] memory result = counterfactualVault.executeCalls(calls);
        // counterfactualVault.destroy(owner);

        emit Executed(erc721, tokenId, msg.sender);

        return result;
    }

    /// @notice Computes the Counterfactual Wallet address for an address.
    /// @dev The contract will not exist yet, so the address will have no code.
    /// @param vaultIds The vaultIds (vault nonce)
    /// @return The address of the Counterfactual Vault
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
    /// @param owner The ERC721 address
    /// @param vaultId The ERC721 token id
    /// @return The address of the newly created CounterfactualVault.
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

    /// @notice Computes the CREATE2 salt for the given ERC721 token.
    /// @param owner The owners address
    /// @param vaultId The vaultId
    /// @return A bytes32 value that is unique to that ERC721 token.
    function _salt(
        address owner,
        uint256 vaultId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, vaultId));
    }
}
