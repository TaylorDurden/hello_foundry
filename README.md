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
