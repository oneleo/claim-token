## ClaimToken Contract

The `ClaimToken` contract facilitates secure and efficient token distribution for events. It allows administrators to manage token-based events and signers, while ensuring users can claim their allocated tokens once, using a valid signature from authorized signers.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Coverage

```shell
$ forge coverage --report summary --match-path 'test/*.t.sol' --no-match-coverage '(script/|test/)' | sed '/^[^|]/d' | sed '/^$/d'
```

- Foundry coverage result

| File               | % Lines         | % Statements    | % Branches      | % Funcs         |
| ------------------ | --------------- | --------------- | --------------- | --------------- |
| src/ClaimToken.sol | 100.00% (48/48) | 100.00% (64/64) | 100.00% (21/21) | 100.00% (12/12) |
| Total              | 100.00% (48/48) | 100.00% (64/64) | 100.00% (21/21) | 100.00% (12/12) |

### Deploy and verify

- Copy and modify the deployment variables with `cp .env.example .env`, then run the following command.
- The claimToken contract address will be saved in `script/Address.json`.

```shell
$ chmod +x script/DeployClaimToken.sh
$ script/DeployClaimToken.sh
```
