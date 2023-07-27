# Cryptoconomy

**SteadyCoin - Algorithmically Stable Stablecoin on Polygon ZK-EVM**


## Overview

SteadyCoin (STC) is an algorithmically stable stablecoin built on the Polygon ZK-EVM blockchain. It aims to provide a stable store of value by pegging its value to the average price of a basket of goods and services. The stability of SteadyCoin is achieved through an algorithmic mechanism, and it is exogenously collateralized to ensure its value is backed by real-world assets. This documentation provides an overview of the SteadyCoin ecosystem, its key components, and its features.

## Core Smart Contracts

### 1. ERC20 Smart Contract

The ERC20 smart contract serves as the core of the SteadyCoin token. It adheres to the ERC20 standard, allowing seamless integration with various decentralized applications (DApps) and exchanges. The contract includes functions for minting and burning tokens based on the algorithmic stability mechanism and the basket of goods and services. The total supply of SteadyCoin is determined by the underlying algorithm and the collateralization level.

### 2. Engines Smart Contract

The Engines smart contract is a crucial component of SteadyCoin's stability mechanism. It ensures that the value of 1 STC token remains equal to the average price of the basket of goods and services. The Engines contract consumes events that provide the average price data and applies the necessary adjustments to maintain the peg. By controlling the token supply and dynamically adjusting it based on the average price, the Engines contract plays a vital role in stabilizing SteadyCoin.

### 3. Dynamic NFT Contract

The Dynamic NFT contract houses the basket of goods and services. While it acts as a non-fungible token (NFT) contract, it is unique in its dynamic nature. The NFT token represents the collection of real-world assets, goods, and services that form the basis for calculating the average price. Through this contract, the market can aggregate and calculate the average price, which is then fed into the Engines contract for stability adjustments.

## Stability and Collateralization

SteadyCoin is considered exogenously collateralized, meaning its stability and value are backed by a real-world basket of goods and services. This collateralization mechanism ensures that SteadyCoin maintains its peg to the average price, mitigating the risk of significant fluctuations. The algorithmic stability of SteadyCoin, coupled with its collateralization, provides a reliable and predictable stablecoin that users can trust as a store of value.

**Properties:**

**Exogenously Collateralized**
SteadyCoin is exogenously collateralized, meaning that its total supply is backed by the real-world assets represented in the dynamic NFT contract. The value of these assets ensures the stability and intrinsic value of SteadyCoin, providing trust to users and mitigating counterparty risks.

**Pegged to Basket of Goods and Services**
The stability of SteadyCoin is maintained by pegging it to the average price of a diversified basket of goods and services represented by the dynamic NFT contract. This basket's composition may evolve over time, reflecting changes in the market and ensuring an accurate representation of the economy.

**Algorithmically Stable**
The algorithmic stability mechanism dynamically adjusts the supply of SteadyCoin based on the changes in the average price of the basket of goods and services. As the market fluctuates, the supply of SteadyCoin expands or contracts, ensuring that its value remains closely tied to the underlying assets.

## Future Considerations
SteadyCoin is an innovative stablecoin project with immense potential for growth and adoption. To enhance its utility and value, the following considerations should be taken into account:

- Rigorous Security Audits: Conduct regular security audits to ensure the robustness and integrity of the smart contracts, safeguarding user funds and data.

- Integration with DeFi Ecosystem: Explore integration opportunities with decentralized finance (DeFi) platforms to facilitate lending, borrowing, and other financial services using SteadyCoin.

- Community Governance: Consider implementing a decentralized governance mechanism where holders of SteadyCoin can participate in decision-making processes for protocol upgrades and adjustments.


## Conclusion

SteadyCoin represents a novel approach to stablecoin design, leveraging algorithmic stability and real-world asset collateralization to maintain a stable value. The integration of the dynamic NFT contract and the Engines contract ensures that the stablecoin remains resilient against market fluctuations. By pegging its value to a diversified basket of goods and services, SteadyCoin aims to provide users with a reliable, transparent, and secure stablecoin on the Polygon ZK-EVM blockchain.


References:

1. Cryptoconomy: https://docs.google.com/document/d/1dOsyn1y-sQxV-P4S8tFBFoUEuzfMFfAou0bUEeE49xA
2. Blockchain Economy: https://docs.google.com/document/d/1E2ytBCuSK4g2zLKyqJeCOHLqvxE5xfBELhcgPqZlKlk