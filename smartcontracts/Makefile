compile:
	npx hardhat compile

test@contract:
	npx hardhat test

test@forge:
	forge test

test@forge-verbose:
	forge test -vv

test@forge-full-verbose:
	forge test -vvvv

test@contract-gas:
	REPORT_GAS=true npx hardhat test

test@forge-gas:
	forge test --gas-report

local@network:
	npx hardhat node

deploy@local:
	npx hardhat run --network localhost scripts/deploy.ts

deploy@network:
	npx hardhat run scripts/testDeploy.js --network ${NETWORK}

verify@contract:
	npx hardhat verify --network ${NETWORK} --constructor-args ${ARG_FILENAME} ${ADDRESS}
