// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

import "../src/CounterfactualVaultControllerFactory.sol";

contract TestCounterfactualVaultControllerFactory is Test {
    CounterfactualVaultControllerFactory cfwcf;
    CounterfactualVaultController cfwc;

    function setUp() public {
        cfwcf = new CounterfactualVaultControllerFactory();
    }

    function testCreateCounterfactualVaultControllerFactory() public {
        cfwc = cfwcf.createCounterfactualVaultController();
    }
}
