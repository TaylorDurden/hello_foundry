# Inscription Factory Contracts

## Contract Addresses

- InscriptionToken (Implementation): [TOKEN_IMPLEMENTATION_ADDRESS]
- InscriptionFactory (Proxy): [FACTORY_PROXY_ADDRESS]

## Deployment Steps

1. Deploy `InscriptionToken` and note down the address.
2. Deploy `InscriptionFactoryV1`.
3. Upgrade to `InscriptionFactoryV2` using the proxy address.

## Tests

Ensure that the state and behavior remain consistent before and after the upgrade by running the provided tests.
