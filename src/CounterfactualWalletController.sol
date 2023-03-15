// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./external/lib/MinimalProxyLibrary.sol";
import "./CounterfactualWallet.sol";

/// @title Allows users to plunder an address associated with an ERC721
/// @notice Counterfactually instantiates a wallet at an address unique to an ERC721 token.  The address for an ERC721 token can be computed and later
/// plundered by transferring token balances to the ERC721 owner.
contract CounterfactualWalletController is Ownable {
    CounterfactualWallet public counterfactualWalletInstance;

    bytes32 internal immutable _counterfactualWalletBytecodeHash;
    bytes internal _counterfactualWalletBytecode;

    /// @notice Emitted when a wallet is swept
    event Sweep(
        address indexed erc721,
        uint256 indexed tokenId,
        address indexed operator
    );

    /// @notice Emitted when a wallet is executed
    event Executed(
        address indexed erc721,
        uint256 indexed tokenId,
        address indexed operator
    );

    /// @notice Constructs a new controller.
    /// @dev Creates a new CounterfactualWallet instance and an associated minimal proxy.
    constructor() Ownable() {
        counterfactualWalletInstance = new CounterfactualWallet();
        counterfactualWalletInstance.initialize();

        _counterfactualWalletBytecode = MinimalProxyLibrary.minimalProxy(
            address(counterfactualWalletInstance)
        );
        _counterfactualWalletBytecodeHash = keccak256(
            _counterfactualWalletBytecode
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
        CounterfactualWallet.Call[] calldata calls
    ) external onlyOwner returns (bytes[] memory) {
        CounterfactualWallet counterfactualWallet = _createCFWallet(
            erc721,
            tokenId
        );
        (erc721, tokenId);
        bytes[] memory result = counterfactualWallet.executeCalls(calls);
        // counterfactualWallet.destroy(owner);

        emit Executed(erc721, tokenId, msg.sender);

        return result;
    }

    /// @notice Computes the Counterfactual Wallet address for an address.
    /// @dev The contract will not exist yet, so the address will have no code.
    /// @param walletId The walletId ("HD wallet" nonce)
    /// @return The address of the Counterfactual Wallet
    function computeAddress(uint256 walletId) external view returns (address) {
        return
            Create2Upgradeable.computeAddress(
                _salt(owner(), walletId),
                _counterfactualWalletBytecodeHash
            );
    }

    /// @notice Creates a CounterfactualWallet for the given owners address.
    /// @param owner The ERC721 address
    /// @param walletId The ERC721 token id
    /// @return The address of the newly created CounterfactualWallet.
    function _createCFWallet(address owner, uint256 walletId)
        internal
        returns (CounterfactualWallet)
    {
        CounterfactualWallet counterfactualWallet = CounterfactualWallet(
            Create2Upgradeable.deploy(
                0,
                _salt(owner, walletId),
                _counterfactualWalletBytecode
            )
        );
        counterfactualWallet.initialize();
        return counterfactualWallet;
    }

    /// @notice Computes the CREATE2 salt for the given ERC721 token.
    /// @param owner The owners address
    /// @param walletId The walletId
    /// @return A bytes32 value that is unique to that ERC721 token.
    function _salt(address owner, uint256 walletId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(owner, walletId));
    }
}
