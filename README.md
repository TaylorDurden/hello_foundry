# hello-foundry

https://github.com/foundry-rs/foundry

https://book.getfoundry.sh/

## Basic

- [x] Install

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

- [x] Init

```shell
forge init
```

- [x] Basic commands

```shell
forge build
forge test
forge test --match-path test/HelloWorld -vvvv
```

---

- [x] Test
  - counter app
  - test setup, ok, fail
  - match
  - verbose
  - gas report

```shell
forge test --match-path test/Counter.t.sol -vvv --gas-report
```

---

- [x] Solidity version and optimizer settings

https://github.com/foundry-rs/foundry/tree/master/config

---

- [x] Remapping

```shell
$ forge remappings
$ forge install transmissions11/solmate
$ forge update lib/solmate
$ forge remove solmate

$ forge install OpenZeppelin/openzeppelin-contracts
```

---
