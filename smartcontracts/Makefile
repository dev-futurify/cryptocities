# running local blockchain with hardhat
local@network:
	npx hardhat node

# forge commands

forge@clean:
	forge clean

forge@update:
	forge update

forge@build:
	forge build

forge@format:
	forge fmt

forge@coverage:
	forge coverage --report debug > coverage-report.txt

forge@snapshot:
	forge snapshot

test@forge:
	forge test

test@forge-verbose:
	forge test -vv

test@forge-verbose-full:
	forge test -vvvv

test@debug-function:
	forge test --debug "$(FUNCTION)"

test@contract-gas:
	REPORT_GAS=true npx hardhat test

test@forge-gas:
	forge test --gas-report

# hardhat commands

hardhat@compile:
	npx hardhat compile

hardhat-deploy@local:
	npx hardhat run --network localhost scripts/deploy.ts

hardhat-deploy@network:
	npx hardhat run scripts/testDeploy.js --network ${NETWORK}

hardhat-versify@contract:
	npx hardhat verify --network ${NETWORK} --constructor-args ${ARG_FILENAME} ${ADDRESS}
