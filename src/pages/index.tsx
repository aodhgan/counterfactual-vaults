import { useAccount } from 'wagmi'

import { Account, Connect, Counter, NetworkSwitcher } from '../components'

function Page() {
  const { isConnected } = useAccount()

  return (
    <>
      <h1>Counterfactual Vaults</h1>

      <Connect />

      {isConnected && (
        <>
          <Account />
          <hr />
          <Counter />
          <hr />
          <NetworkSwitcher />
        </>
      )}
    </>
  )
}

export default Page
