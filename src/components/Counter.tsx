import { waitForTransaction } from '@wagmi/core'
import { BigNumber } from 'ethers'
import { useState } from 'react'
import { useContractEvent, useContractRead, useContractWrite, useNetwork, usePrepareContractWrite, useWaitForTransaction } from 'wagmi'

import {
  counterfactualVaultControllerABI,
  counterfactualVaultControllerFactoryABI,
  erc20PresetMinterPauserABI,
  useOwnableOwner,
} from '../generated'

const factoryAddress = "0xA3f7BF5b0fa93176c260BBa57ceE85525De2BaF4"

export function Counter() {
  const [createdVaultControllerAddress, setCreatedVaultControllerAddress] = useState('');

  // Add a state variable to store the addresses calculated by GetAddresses
  const [computedAddresses, setComputedAddresses] = useState<string[]>([]);

  return (
    <div>
      <CreateVaultController onVaultCreated={setCreatedVaultControllerAddress} />
      {createdVaultControllerAddress && (
        <GetAddresses
          createdVaultControllerAddress={createdVaultControllerAddress}
          onComputedAddresses={setComputedAddresses} // Pass a callback function to receive the computed addresses
        />
      )}
      {computedAddresses.length > 0 && (
        <FundVaults addressesCreated={computedAddresses} /> // Pass the computed addresses as props to FundVaults component
      )}
    </div>
  );
}

function GetAddresses({ createdVaultControllerAddress, onComputedAddresses }: any) {
  const [expanded, setExpanded] = useState(false);

  // create an array of bignumbers from 1 to 10
  const args = Array.from(Array(100).keys()).map((i) => BigNumber.from(i + 1));

  // call caclulateAddresses on createdVaultControllerAddress
  const contractReadResult = useContractRead({
    address: createdVaultControllerAddress,
    abi: counterfactualVaultControllerABI,
    functionName: 'computeAddress',
    args: [args],
  });
  console.log({ contractReadResult });

  const toggleExpanded = () => {
    setExpanded(!expanded);

    // Pass the computed addresses to the callback function
    onComputedAddresses(contractReadResult?.data);
  };

  return (
    <div>
      <div onClick={toggleExpanded}>
        You have a vault at: {createdVaultControllerAddress}
      </div>
      {expanded && (
        <div className="scrollable-container">
          {contractReadResult?.data &&
            contractReadResult.data.map((address, index) => (
              <div key={index}>{address.toString()}</div>
            ))}
        </div>
      )}
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

const erc20Anvil = "0xD855cE0C298537ad5b5b96060Cf90e663696bbf6"

function FundVaults({ addressesCreated }: any) {
  console.log("funding.. ", addressesCreated[1])
  const { config } = usePrepareContractWrite({
    address: erc20Anvil,
    abi: erc20PresetMinterPauserABI,
    functionName: 'mint',
    args: [addressesCreated, BigNumber.from(1000)] // Pass an array of addresses as the first argument
  })
  console.log(config)
  const { data, isSuccess, write } = useContractWrite(config)

  const { isLoading } = useWaitForTransaction({
    hash: data?.hash,
    onSuccess: () => console.log("funding transaction!!"),
  })

  return (
    <div>
      <button disabled={!write} onClick={() => write?.()}>
        Fund addresses
      </button>
      {isLoading && <div>Check Wallet</div>}
      {isSuccess && <div>Transaction: {JSON.stringify(data)}</div>}
    </div>
  )
}
