// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

import "../src/CounterfactualVaultController.sol";
import "../src/CounterfactualVaultControllerFactory.sol";

contract TestCounterfactualVaultController is Test {
    CounterfactualVaultController cfwc;
    CounterfactualVaultControllerFactory cfwcf;

    ERC20PresetMinterPauser token;

    function setUp() public {
        cfwcf = new CounterfactualVaultControllerFactory();
        cfwc = cfwcf.createCounterfactualVaultController();
        token = new ERC20PresetMinterPauser("Test", "TST");
    }

    function testExecuteCall() public {
        // create array of vaultIds
        uint256[] memory vaultIds = new uint256[](1);
        vaultIds[0] = 2;

        address[] memory calculatedAddresses = cfwc.computeAddress(vaultIds);
        // mint some tokens to the calculated address
        token.mint(calculatedAddresses[0], 100);

        // executeCall to transfer the tokens to a random address
        address randomAddress = address(0x123);

        // create a call struct
        CounterfactualVault.Call[]
            memory calls = new CounterfactualVault.Call[](1);

        // populate the call struct
        calls[0] = CounterfactualVault.Call({
            to: address(token),
            value: 0,
            data: abi.encodeWithSignature(
                "transfer(address,uint256)",
                randomAddress,
                100
            )
        });

        cfwc.executeCalls(2, calls);

        assertEq(token.balanceOf(randomAddress), uint256(100), "ok");
        assertEq(token.balanceOf(calculatedAddresses[0]), uint256(0), "ok");
    }
    // function testFoo(uint256 x) public {
    //     vm.assume(x < type(uint128).max);
    //     assertEq(x + x, x * 2);
    // }
}
