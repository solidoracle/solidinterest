.PHONY: test

# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
# change ETH_RPC_URL to another one (e.g., FTM_RPC_URL) for different chains
MAINNET_FORK_URL := ${ETH_RPC_URL} 
GOERLI_RPC_URL := ${GOERLI_RPC_URL}
POLYGON_FORK_URL := ${POLYGON_RPC_URL} 
MUMBAI_FORK_URL := ${MUMBAI_RPC_URL} 

# For deployments. Add all args without a comma
# ex: 0x316..FB5 "Name" 10
constructor-args := 

build  :; forge build
test-polygon   :; forge test --fork-url ${POLYGON_FORK_URL}
test-polygon-log   :; forge test -vv --fork-url ${POLYGON_FORK_URL}
trace-polygon   :; forge test -vvvv --fork-url ${POLYGON_FORK_URL}

test-mumbai   :; forge test --fork-url ${MUMBAI_FORK_URL}
trace-mumbai   :; forge test -vvvv --fork-url ${MUMBAI_FORK_URL}


test-mainnet   :; forge test -vvvv --fork-url ${MAINNET_FORK_URL}
test-goerli   :; forge test -vvvv --fork-url ${GOERLI_RPC_URL}


test :; forge test -vv --fork-url ${GOERLI_RPC_URL}
trace :; forge test -vvvvv --fork-url ${GOERLI_RPC_URL}
# trace   :; forge test -vvv --fork-url ${FORK_URL} --etherscan-api-key ${ETHERSCAN_API_KEY}
# test-contract :; forge test -vv --fork-url ${FORK_URL} --match-contract $(contract) --etherscan-api-key ${ETHERSCAN_API_KEY}
# trace-contract :; forge test -vvv --fork-url ${FORK_URL} --match-contract $(contract) --etherscan-api-key ${ETHERSCAN_API_KEY}
# deploy	:; forge create --rpc-url ${FORK_URL} --constructor-args ${constructor-args} --private-key ${PRIV_KEY} src/Strategy.sol:Strategy --etherscan-api-key ${ETHERSCAN_API_KEY} --verify
# local tests without fork
test-local  :; forge test
trace-local  :; forge test -vvv
clean  :; forge clean
snapshot :; forge snapshot
