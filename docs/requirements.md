# Cryptocities Modules

### Steady Marketplace

1. Any users can become a vendor as long they creates a `collection`
    - 1 collection belongs to 1 vendor, and the marketplace shall have many vendors
    - **NEW FEAT**: charge to become a vendor in the marketplace
2. Users able to list their items/products on the marketplace based on the `12 main categories` in the `basket of good and services`
    - Then based from the user `selection`, create for them an ERC721 or ERC1155 contract
3. Each collection can have multiple categories they can choose to sell on the marketplace.
    - Vendor can only list/delist their items when a collection is created
    - All of the items listed/delisted will be associate with the vendor's collection address
4. The smart contract "need to grab" these data to feed to the `Engine`
    - Total Volume of Sales of the collection
    - Floor price
    - Product listed percentage
    - Owners of the NFT (the customer that purchased the items/product)
5. Vendor able to withdraw their fund based on the amount they wanted or fully
    - will add some sort of protector to prevent vendor withdraw fully to "keep the economy alive"
6. The Owner (Futurify & EpicStartups) shall be able to withdraw the vendor fund - `TO BE DAO`

### Steady Engine 

1. Fetch the "data needed" from the `marketplace` to feed it in the contract of the `engine algorithm`
    - HOW the engine algorithm works and how can we determine 1 SteadyCoin == Average Price of the Basket of Good and Services
    - Need to be based on the `Consumer Price Index` of each categories, then combine the price and get the average
2. The stablecoin most probably need some collateral to keep the `liquidity` of the economy 
3. In charge of minting and burning the token, and airdropping (incentivize) token to the users

### Steady Coin

1. Automated Minting and Burning by the Engine
2. Automated Airdrop by the Engine - Needed to keep people spending on the economy to keep it `under control`


