compile:
	npx hardhat compile

test:
	npx hardhat test

test@report-gas:
	REPORT_GAS=true npx hardhat test

local@network:
	npx hardhat node

deploy@local:
	npx hardhat run --network localhost scripts/deploy.ts

deploy:
	npx hardhat run scripts/testDeploy.js --network ${NETWORK}

verify@contract:
	npx hardhat verify --network ${NETWORK} --constructor-args ${ARG_FILENAME} ${ADDRESS}
