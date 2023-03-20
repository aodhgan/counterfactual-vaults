import { waitForTransaction } from '@wagmi/core'
import { BigNumber } from 'ethers'
import { useState } from 'react'
import { useContractEvent, useContractRead, useContractWrite, useNetwork, usePrepareContractWrite, useWaitForTransaction } from 'wagmi'

import {
  counterfactualVaultControllerABI,
  counterfactualVaultControllerFactoryABI,
  useOwnableOwner,
} from '../generated'

export function Counter() {
  const [createdVaultControllerAddress, setCreatedVaultControllerAddress] = useState('');

  return (
    <div>
      <CreateVaultController onVaultCreated={setCreatedVaultControllerAddress} />
      {createdVaultControllerAddress && <GetAddresses createdVaultControllerAddress={createdVaultControllerAddress} />}
    </div>
  )
}

const factoryAddress = "0xF32659FA35e8B3c7daFb061702043a24b75793dE"

function GetAddresses({ createdVaultControllerAddress }: any) {


  // create an array of bignumbers from 1 to 10
  const args = Array.from(Array(100).keys()).map((i) => BigNumber.from(i + 1))

  // call caclulateAddresses on createdVaultControllerAddress
  const contractReadResult = useContractRead({
    address: createdVaultControllerAddress,
    abi: counterfactualVaultControllerABI,
    functionName: 'computeAddress',
    args: [args],
  })
  console.log({ contractReadResult })
  return (
    <div>
      <div>You have a vault at: {createdVaultControllerAddress}</div>
      <div className="scrollable-container">
        {contractReadResult?.data &&
          contractReadResult.data.map((address, index) => (
            <div key={index}>{address.toString()}</div>
          ))}
      </div>
    </div>
  );

}


function CreateVaultController({ onVaultCreated }: any) {
  const { data: count } = useOwnableOwner()

  const { config } = usePrepareContractWrite({
    address: factoryAddress,
    abi: counterfactualVaultControllerFactoryABI,
    functionName: 'createCounterfactualVaultController',
  })
  const { data, isSuccess, write } = useContractWrite(config)

  const { isLoading } = useWaitForTransaction({
    hash: data?.hash,
    onSuccess: () => console.log("sent transaction!!"),
  })



  useContractEvent({
    address: factoryAddress,
    abi: counterfactualVaultControllerFactoryABI,
    eventName: 'CounterfactualVaultControllerCreated',
    listener(creator, vault) {
      console.log("the event happened!")
      console.log({ vault })
      console.log({ creator })

      onVaultCreated(vault);
    },
  })

  return (
    <div>
      <button disabled={!write} onClick={() => write?.()}>
        Create Counterfactual Vault
      </button>
      {isLoading && <div>Check Wallet</div>}
      {isSuccess && <div>Transaction: {JSON.stringify(data)}</div>}

    </div>
  )
}