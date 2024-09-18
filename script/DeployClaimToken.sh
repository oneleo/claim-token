source .env

forge script script/DeployClaimToken.s.sol --fork-url ${BASE_SEPOLIA_NODE_RPC_URL} --broadcast --use 0.8.27 --slow --chain-id 84532 --etherscan-api-key ${BASESACN_API_KEY} --verify

# If verification fails, it will be re-verified here.
if [ $? -eq 0 ]; then
        contractAddress=$(jq -r '.Base_Sepolia.claimToken' script/output/Address.json)

        forge verify-contract --watch --chain 84532 --verifier "etherscan" --etherscan-api-key ${BASESACN_API_KEY} --compiler-version 0.8.27 --constructor-args $(cast abi-encode "constructor(address, address[])" ${CLAIM_TOKEN_ADMIN_ADDRESS} [${CLAIM_TOKEN_SIGNER_ADDRESS}]) ${contractAddress} "src/ClaimToken.sol:ClaimToken"
fi
