// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CounterfactualVaultController.sol";

contract CounterfactualVaultControllerFactory {
    event CounterfactualVaultControllerCreated(
        address indexed creator,
        address indexed counterfactualVaultController
    );

    function createCounterfactualVaultController()
        external
        returns (CounterfactualVaultController)
    {
        CounterfactualVaultController created = new CounterfactualVaultController(
                msg.sender
            );
        emit CounterfactualVaultControllerCreated(msg.sender, address(created));
        return created;
    }
}
