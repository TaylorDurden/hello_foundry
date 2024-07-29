# Inscription Factory Contracts

## Contract Addresses

- UUPS Proxy (Proxy): [https://sepolia.etherscan.io/address/0x578e343abe891a8b4144358a1572a5775aa95116#code]
- InscriptionFactoryV1 (Implementation): [https://sepolia.etherscan.io/address/0x704aeb55476b303e3d3c142d48bbf374dce1eb3c#code]
- InscriptionFactoryV2 (Implementation): [https://sepolia.etherscan.io/address/0x92ce697bf55cb94b469089fae16b85a5e614887a#code]
- InscriptionToken for Minial Proxy Contract: [https://sepolia.etherscan.io/address/0xa628d2048c0e832a492ff9a3cb9d5a701828acac#code]

## Deployment Steps

1. Deploy `Token factory V1 and UUPS porxy` use below bash command:

```bash
bash ./script/deploy.sh --file ./script/DeployUUPSTokenFactoryV1.s.sol --account <your-keystore-account>
```

2. Upgrade to `InscriptionFactoryV2` using the proxy address

```bash
bash ./script/deploy.sh --file ./script/DeployUUPSTokenFactoryV2.s.sol --account <your-keystore-account>
```

## Tests

```bash
forge clean && forge test -vvvv --match-path ./test/Upgradable/UUPSTokenFactory.t.sol
```
