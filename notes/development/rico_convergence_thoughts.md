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

### Steady Marketplace

purchase items/products via NFT - user can track what items/products they have bought/consumed and at the same time they can track their expenses (view history) on specific vendors?

marketplace need to keep track of the unit price of the product, total products sold across every vendors + by categories

users unable resell the token once bought ?

only vendors can list items, create update delete items - add quantities etc. 
