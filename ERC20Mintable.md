## Deploy ERC20Mintable contract

- Set environments

```shell
$ NODE_RPC_URL="XXX" \
&& DEPLOYER_PRIVATE_KEY="XXX" \
&& COMPILER_VERSION="0.8.27" \
&& CHAIN_ID="XXX" \
&& ETHERSCAN_API_KEY="XXX"

$ NAME="TEST Token" && SYMBOL="TEST" && DECIMALS="18"
```

- Deploy ERC20Mintable contract

```shell
$ TOKEN_ADDRESS=$(forge create --rpc-url ${NODE_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --use ${COMPILER_VERSION} "src/ERC20Mintable.sol:ERC20Mintable" --constructor-args ${NAME} ${SYMBOL} ${DECIMALS} | sed -nr 's/^Deployed to: (0x[0-9a-zA-Z]{40})[.]*$/\1/p') \
&& echo ${TOKEN_ADDRESS}
```

- Verify ERC20Mintable contract

```shell
$ forge verify-contract --watch --chain ${CHAIN_ID} --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version ${COMPILER_VERSION} --constructor-args $(cast abi-encode "constructor(string memory name, string memory symbol, uint8 initialDecimals)" ${NAME} ${SYMBOL} ${DECIMALS}) ${TOKEN_ADDRESS} "src/ERC20Mintable.sol:ERC20Mintable"
```
