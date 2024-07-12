#!/bin/bash

# effect the env vars
source .env

# get bash arg
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --file) SCRIPT_FILE="$2"; shift ;;
    --account) ACCOUNT="$2"; shift ;;
    *) echo "unknown arg: $1" ; exit 1 ;;
  esac
  shift
done

# make sure the script file was provided
if [[ -z "$SCRIPT_FILE" ]]; then
  echo "Please specify --file <your_script_path>"
  exit 1
fi

if [[ -z "$ACCOUNT" ]]; then
  echo "Please specify --account <your_cast_wallet_account>"
  exit 1
fi

# check if the env vars was defined preceedly
if [[ -z "$SEPOLIA_RPC_URL" || -z "$ETHERSCAN_API_KEY" || -z "$CHAIN_ID" ]]; then
  echo "Please ensure .env defines the vars：SEPOLIA_RPC_URL, ETHERSCAN_API_KEY, CHAIN_ID"
  exit 1
fi

if [[ -z "$PRIVATE_KEY" ]]; then
  echo "Can not load the private key from keystore..."
  exit 1
fi

# deploy
forge script "$SCRIPT_FILE" \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --broadcast \
  --verify \
  --etherscan-api-key "$ETHERSCAN_API_KEY" \
  --account $ACCOUNT \
  -vvvv