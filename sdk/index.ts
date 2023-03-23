import { BigNumber, ethers } from "ethers";

import { counterfactualVaultControllerABI, counterfactualVaultControllerFactoryABI, erc20ABI } from "../src/generated";


type Vault = {
    vaultId: number;
    address: string;
    balance: BigNumber;
}
const erc20MintableOnGoerli = "0x66ee871f085b93eb37f95d135774eff4d402e694"
const factoryAddressGoerli = "0x419958caff2751a1639db5d7fab571a042d4bd86"

export async function sweepErc20Amounts(amount: BigNumber, to: string, vaultControllerAddress: string, erc20Address: string, vaultIds: number[]) {
    // create an ethers contract instance for counterfactualVaultControllerABI
    const vaultControllerContract = new ethers.Contract(vaultControllerAddress, counterfactualVaultControllerABI);
    // get vault addresses
    const vaultAddresses: string[] = vaultControllerContract.computeAddress(vaultIds)
    // get balance of vault addresses
    const erc20Contract = new ethers.Contract(erc20Address, erc20ABI);
    const vaultBalances = await Promise.all(vaultAddresses.map((vaultAddress: string) => erc20Contract.balanceOf(vaultAddress)))
    // populate Vault objects
    const vaults: Vault[] = vaultAddresses.map((address: string, index: number) => ({ vaultId: vaultIds[index], address, balance: vaultBalances[index] }))

    // sort vaults by balance (high to low)
    const sortedVaults = vaults.sort((a, b) => b.balance.sub(a.balance).toNumber())

    // slice array of vaults so sufficient balances are met for amount 
    const vaultsToSweep = sortedVaults.slice(0, sortedVaults.findIndex((vault) => vault.balance.lt(amount)))
    console.log(`Sweeping ${amount.toString()} from ${vaultsToSweep.length} vaults..`)
    let vaultCalls: any[] = []
    vaultsToSweep.forEach((vault) => {
        console.log(`Sweeping ${vault.balance} from  vault address ${vault.address}}`)

        const vaultCall = {
            vaultId: vault.vaultId,
            call: {
                erc20Address: erc20Address,
                value: 0,
                data: erc20Contract.interface.encodeFunctionData("transfer", [to, vault.balance])
            }
        }
        console.log("pushing vault call ", vaultCall)
        vaultCalls.push(vaultCall)
    })

    // to do calculate change amount if any

    // construct tx data to transfer erc20 tokens from vaults to specified `to` address
    /*
        struct VaultCall {
            uint256 vaultId;
            CounterfactualVault.Call[] call;
        }
        where 
            struct Call {
            address to;
            uint256 value;
            bytes data;
        }
        and the function signautre is:     function executeVaultCalls(
            VaultCall[] calldata vaultCalls
        ) external
    */
    await vaultControllerContract.executeVaultCalls(vaultCalls)
    console.log("done!")

}
export async function createCounterfactualVaultControllerFromFactory() {
    // create a factory contract instance
    const factoryContract = new ethers.Contract(factoryAddressGoerli, counterfactualVaultControllerFactoryABI)
    // create a counterfactual vault controller
    const tx = await factoryContract.createCounterfactualVaultController()
    // get the address of the newly created counterfactual vault controller from the event
    const receipt = await tx.wait()
    const vaultControllerAddress = receipt.events[0].args[0]
    console.log("vault controller address: ", vaultControllerAddress)
    return vaultControllerAddress
}