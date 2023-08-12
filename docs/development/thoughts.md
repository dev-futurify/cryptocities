## Steady Coin layouts

### ERC20
Layout of Contract:

```yaml
version
imports
errors
interfaces, libraries, contracts
Type declarations
State variables
Events
Modifiers
Functions
```

Layout of Functions:

```yaml
constructor
receive function (if exists)
fallback function (if exists)
external
public
internal
private
view & pure functions
```

### Engine
Layout of Contract:

```yaml
version
imports
errors
interfaces, libraries, contracts
Type declarations
State variables
Events
Modifiers
Functions
```

Layout of Functions:

```yaml
constructor
receive function (if exists)
fallback function (if exists)
external
public
internal
private
internal & private view & pure functions
external & public view & pure functions
```

### Steady Marketplace (Data source for SteadyCoin Engine)

1. purchase items/products via NFT - user can track what items/products they have bought/consumed and at the same time they can track their expenses (view history) on specific vendors?

2. marketplace need to keep track of the unit price of the product, total products sold across every vendors + by categories

3. users unable resell the token once bought ? users can do whatever they want with the NFT but most probably it has no value already.

4. only vendors can list items, create update delete items - add quantities etc. 

5. By using the floor price of Cryptocities marketplace, we shall determine the `Consumer Price Index` of the economy - we will start with FnB category first 

6. Formula: CPI_t = (C_t)/(C_0) * 100

CPI_t	=	consumer price index in current period
C_t	=	cost of market basket in current period
C_0	=	cost of market basket in base period

7. It will correlates with the inflation rate as well

8. Cryptocities Index ? 👀  - data is collected from the SteadyMarketplace NFT floor price

9. CPI are based on these 12 main categories
    - Food and Non-alcoholic beverages (THIS)
    - Restaurants & hotels (THIS)
    - Alcoholic beverages and tobacco
    - Clothing and footwear
    - Housing, water, electricity, gas and other fuels
    - Furnishings, household equipment & routine household maintenance
    - Health
    - Transport
    - Communication
    - Recreation services & culture
    - Education
    - Misc. goods & services

10. To comply with the gov "maybe" might need to do something like how paypal does with its stablecoin - freeze and lock functionality (admin only) 