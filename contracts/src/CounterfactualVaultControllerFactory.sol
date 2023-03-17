// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CounterfactualVaultController.sol";

contract CounterfactualVaultControllerFactory {
    function createCounterfactualVaultController()
        external
        returns (CounterfactualVaultController)
    {
        return new CounterfactualVaultController(msg.sender);
    }
}
