# hello-foundry

https://github.com/foundry-rs/foundry

https://book.getfoundry.sh/

## Basic

- [x] Install

```shell
$ curl -L https://foundry.paradigm.xyz | bash
$ foundryup
```

- [x] Init

```shell
$ forge init
```

- [x] Basic commands

```shell
$ forge build
$ forge test
$ forge test --match-path test/HelloWorld -vvvv
```

---

- [x] Test
  - counter app
  - test setup, ok, fail
  - match
  - verbose
  - gas report

```shell
$ forge test --match-path test/Counter.t.sol -vvv --gas-report
```

---

- [x] Solidity version and optimizer settings

https://github.com/foundry-rs/foundry/tree/master/config

---

- [x] Remapping

```shell
$ forge install transmissions11/solmate
$ forge update lib/solmate
$ forge remove solmate

$ forge install OpenZeppelin/openzeppelin-contracts

$ forge remappings
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
ds-test/=lib/solmate/lib/ds-test/src/
erc4626-tests/=lib/openzeppelin-contracts/lib/erc4626-tests/
forge-std/=lib/forge-std/src/
openzeppelin-contracts/=lib/openzeppelin-contracts/
```

If you got a error underline in vscode, please use below command and reopen vscode editor.

```shell
$ forge remappings > remappings.txt
```

---

- [x] Formatter

```shell
$ forge fmt
```

---

- [x] console (Counter, test, log int)

```shell
forge test --match-path test/Console.t.sol -vv
```

---

## Intermediate

---

- [x] Test auth -->
      `$ forge test -vvvv --match-path test/Auth.t.sol`
- [x] Test error -->
      `$ forge test -vvvv --match-path test/Error.t.sol`
  - `vm.expectRevert`
  - `require` error message
  - custom error
  - error label assertions
- [x] Test event (expectEmit)
  - forge test --match-path test/Event.t.sol -vvvv
- [x] Test time (`Auction.sol`)
  - forge test --match-path test/Time.t.sol -vvvv
- [x] Test send eth (`Wallet.sol`) - hoax, deal
  - forge test --match-path test/Wallet.t.sol -vvvv
- [x] Test signature
  - forge test --match-path test/Signature.t.sol -vvvv
  - forge test --match-path test/app/GaslessTokenTransfer.t.sol -vvv

## Advanced

- [x] mainnet fork

```shell
$ forge test --fork-url $FORK_URL --match-path test/Fork.t.sol -vvv
```

- [x] main fork deal (DAI)

```shell
$ forge test --fork-url $FORK_URL --match-path test/DAI.t.sol -vvv
```

- [ ] crosschain fork

- [x] Fuzzing (assume, bound)

```shell
$ forge test --match-path test/Fuzz.t.sol
```

- [x] Invariant

```shell
# Open testing
$ forge test --match-path test/invariants/Invariant_0.t.sol -vvv
$ forge test --match-path test/invariants/Invariant_1.t.sol -vvv
# Handler
$ forge test --match-path test/invariants/Invariant_2.t.sol -vvv
# Actor management
$ forge test --match-path test/invariants/Invariant_3.t.sol -vvv
```

- [x] FFI

```shell
$ forge test --match-path test/FFI.t.sol --ffi -vvv
```

- [x] Differential testing

```shell
# virtual env
$ python3 -m pip install --user virtualenv
$ virtualenv -p python3 venv
$ source venv/bin/activate

$ pip install eth-abi
```

```shell
$ FOUNDRY_FUZZ_RUNS=100 forge test --match-path test/DifferentialTest.t.sol --ffi -vvv
```

## Misc

- [x] Vyper

https://github.com/0xKitsune/Foundry-Vyper

0. Install vyper

```shell
# virtual env
$ python3 -m pip install --user virtualenv
$ virtualenv -p python3 venv
$ source venv/bin/activate

$ pip3 install vyper==0.3.7

# Check installation
$ vyper --version
```

1. Put Vyper contract inside `vyper_contracts`
2. Declare Solidity interface inside `src`
3. Copy & paste `lib/utils/VyperDeployer.sol`
4. Write test

```shell
$ forge test --match-path test/Vyper.t.sol --ffi
```

- [x] ignore error code

```
ignored_error_codes = ["license", "unused-param", "unused-var"]
```

- [x] Deploy

```shell
$ source .env

$ forge script script/Token.s.sol:TokenScript --rpc-url $SEPOLIA_RPC_URL --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify -vvvv
```

- [x] Inspect

forge-inspect - Get specialized information about a smart contract

https://book.getfoundry.sh/reference/forge/forge-inspect?highlight=forge%20inspect#forge-inspect

- [x] Cast example

https://book.getfoundry.sh/cast/

Import, list and remove wallet

```shell
# Import private key
ACCOUNT=burner
cast wallet import $ACCOUNT --private-key PRIVATE_KEY

# List wallets
cast wallet list

# Wallet saved to ~/.foundry/keystores
ls ~/.foundry/keystores/

# Remove wallet
rm -rf ~/.foundry/keystores/$ACCOUNT
```

Send transaction and query contract

```shell
$ DST=0x3aaee3149aCFD9d0e536CA7C1526cB010fa88Cdd
$ FUNC_SIG="set(uint256)"
$ ARGS="777"
$ RPC=https://eth-goerli.g.alchemy.com/v2/y-OzRlSG33yMwy4IfvVD3WlUByo0K0Lq

# Send tx
$ cast send --account $ACCOUNT --rpc-url $RPC $DST $FUNC_SIG $ARGS

# Query smart contract
$ cast call --rpc-url $RPC $DST "val()(uint256)"
```

- [ ] Forge geiger

`forge-geiger` - Detects usage of unsafe cheat codes in a foundry project and its dependencies.

```shell
$ forge geiger
```
