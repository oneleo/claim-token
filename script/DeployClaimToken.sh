source .env

# Deploy the contract to Sepolia network
forge script script/DeployClaimToken.s.sol --fork-url ${SEPOLIA_NODE_RPC_URL} --broadcast --use 0.8.27 --evm-version shanghai --slow --chain-id 11155111 --etherscan-api-key ${ETHERSCAN_API_KEY} --verify

# If verification fails, it will be re-verified here.
if [ $? -ne 0 ]; then
        contractAddress=$(jq -r '.Sepolia.claimToken' script/output/ClaimToken.json)

        forge verify-contract --watch --chain 11155111 --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version 0.8.27 --evm-version shanghai --constructor-args $(cast abi-encode "constructor(address, address[])" ${CLAIM_TOKEN_ADMIN_ADDRESS} "[${CLAIM_TOKEN_SIGNER_ADDRESS}]") ${contractAddress} "src/ClaimToken.sol:ClaimToken"
fi

# Deploy the contract to Arbitrum Sepolia network
forge script script/DeployClaimToken.s.sol --fork-url ${ARB_SEPOLIA_NODE_RPC_URL} --broadcast --use 0.8.27 --evm-version shanghai --slow --chain-id 421614 --etherscan-api-key ${ARBISCAN_API_KEY} --verify

# If verification fails, it will be re-verified here.
if [ $? -ne 0 ]; then
        contractAddress=$(jq -r '.Base_Sepolia.claimToken' script/output/ClaimToken.json)

        forge verify-contract --watch --chain 421614 --verifier "etherscan" --etherscan-api-key ${ARBISCAN_API_KEY} --compiler-version 0.8.27 --evm-version shanghai --constructor-args $(cast abi-encode "constructor(address, address[])" ${CLAIM_TOKEN_ADMIN_ADDRESS} "[${CLAIM_TOKEN_SIGNER_ADDRESS}]") ${contractAddress} "src/ClaimToken.sol:ClaimToken"
fi

# Deploy the contract to Base Sepolia network
forge script script/DeployClaimToken.s.sol --fork-url ${BASE_SEPOLIA_NODE_RPC_URL} --broadcast --use 0.8.27 --evm-version shanghai --slow --chain-id 84532 --etherscan-api-key ${BASESCAN_API_KEY} --verify

# If verification fails, it will be re-verified here.
if [ $? -ne 0 ]; then
        contractAddress=$(jq -r '.Base_Sepolia.claimToken' script/output/ClaimToken.json)

        forge verify-contract --watch --chain 84532 --verifier "etherscan" --etherscan-api-key ${BASESCAN_API_KEY} --compiler-version 0.8.27 --evm-version shanghai --constructor-args $(cast abi-encode "constructor(address, address[])" ${CLAIM_TOKEN_ADMIN_ADDRESS} "[${CLAIM_TOKEN_SIGNER_ADDRESS}]") ${contractAddress} "src/ClaimToken.sol:ClaimToken"
fi

# Deploy the contract to Polygon Amoy network
forge script script/DeployClaimToken.s.sol --fork-url ${POLYGON_AMOY_NODE_RPC_URL} --broadcast --use 0.8.27 --evm-version shanghai --slow --chain-id 80002 --etherscan-api-key ${POLYGONSCAN_API_KEY} --verify

# If verification fails, it will be re-verified here.
if [ $? -ne 0 ]; then
        contractAddress=$(jq -r '.Amoy.claimToken' script/output/ClaimToken.json)

        forge verify-contract --watch --chain 80002 --verifier "etherscan" --etherscan-api-key ${POLYGONSCAN_API_KEY} --compiler-version 0.8.27 --evm-version shanghai --constructor-args $(cast abi-encode "constructor(address, address[])" ${CLAIM_TOKEN_ADMIN_ADDRESS} "[${CLAIM_TOKEN_SIGNER_ADDRESS}]") ${contractAddress} "src/ClaimToken.sol:ClaimToken"
fi
