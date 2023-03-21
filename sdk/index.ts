import { BigNumber, ethers } from "ethers";

import { counterfactualVaultControllerABI, erc20ABI } from "../src/generated"


export async function sweepErc20Amounts(amount: BigNumber, to: string, vaultControllerAddress: string, erc20Address: string, vaultIds: number[]) {
    // create an ethers contract instance for counterfactualVaultControllerABI
    const vaultControllerContract = new ethers.Contract(vaultControllerAddress, counterfactualVaultControllerABI);
    // get vault addresses
    const vaultAddresses: string[] = vaultControllerContract.computeAddress(vaultIds)
    // get balance of vault addresses
    const erc20Contract = new ethers.Contract(erc20Address, erc20ABI);
    const vaultBalances = await Promise.all(vaultAddresses.map((vaultAddress: string) => erc20Contract.balanceOf(vaultAddress)))

    // sort vaults by balance (high to low)
    const sortedVaults = vaultBalances.map((balance: BigNumber, index: number) => ({ balance, index })).sort((a, b) => b.balance.sub(a.balance).toNumber())

    // slice array of vaults so sufficient balances are met for amount 
    const vaultsToSweep = sortedVaults.slice(0, sortedVaults.findIndex((vault) => vault.balance.lt(amount)))

    // construct tx data to transfer erc20 tokens from vaults to specified `to` address

    vaultsToSweep.forEach((vault) => {
        await vaultControllerContract.executeCalls(vault,
            [{ to: erc20Address, value: 0, data: erc20Contract.interface.encodeFunctionData("transfer", [to,]) }])
    }
    




}


