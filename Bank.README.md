# Bank Smart Contract Documentation

## Overview

The Bank contract is a secure and efficient way to manage deposits and withdrawals on the blockchain. It provides the following functionalities:

- Accepts direct deposits via wallets such as Metamask.
- Maintains a record of deposit amounts for each participant's address.
- Includes an administrator-restricted `withdraw()` method for fund management.
- Utilizes an array to track the top 3 deposit amounts among all users.

## Source

- **Contract Name**: Bank
- **File**: [Bank.sol](./src/Bank.sol)
- **Foundry test file**: [Bank.t.sol](./test/Bank.t.sol)
- **Test command**: `forge test -vvvv --match-path ./test/Bank.t.sol`

## Key Features

1. **Direct Deposits**

   - Users can send funds directly to the Bank contract address using their web3 wallets.

2. **Deposit Tracking**

   - The contract keeps an accurate record of the total deposits made by each address.

3. **Withdrawal Access Control**

   - The `withdraw()` method is protected and accessible only by the designated administrator.

4. **Top Depositors Recognition**
   - An array is used to record and honor the top 3 depositors within the contract.

## Contract Interaction

- **Depositing Funds**

  - Users can send Ether to the contract address, which will be automatically credited to their respective balances.

- **Withdrawing Funds**
  - Only the administrator can call the `withdraw()` method to transfer funds from the contract to a specified address.

## Administration

- The contract must be deployed by an administrator who will have exclusive access to the withdrawal functionality.

## Security Measures

- Access to the `withdraw()` method is strictly limited to the administrator to prevent unauthorized access to the contract's funds.

## Deployment

- The Bank contract should be deployed on a supported blockchain network using a compatible web3 wallet or deployment tool.

## Usage

- After deployment, the contract address can be shared with users who wish to deposit funds.
- The administrator can monitor the top depositors and manage withdrawals as needed.

## Disclaimer

This documentation is for informational purposes only. Users are advised to review the [Bank.t.sol](./src/Bank.sol) source code and consult with a smart contract developer before deploying or interacting with the Bank contract.
