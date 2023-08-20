### Convergence thoughts writeups

1. purchase items/products via NFT - user can track what items/products they have bought/consumed and at the same time they can track their expenses (view history) on specific vendors?

2. marketplace need to keep track of the unit price of the product, total products sold across every vendors + by categories

3. users unable resell the token once bought ? users can do whatever they want with the NFT but most probably it has no value already.

4. only vendors can list items, create update delete items - add quantities etc. 

5. By using the floor price of Cryptocities marketplace, we shall determine the `Consumer Price Index` of the economy - we will start off with measuring the CPI first to control the Minting, Burning and Airdropping.

6. Formula: CPI_t = (C_t)/(C_0) * 100
where:
```yaml
CPI_t	=   consumer price index in current period
C_t	    =	cost of market basket in current period
C_0	    =	cost of market basket in base period

current period - current year
base period -  previous year

---

Inflation Rate

(New CPI−Prior CPI/Prior CPI) × 100

```



7. It will correlates with the inflation rate as well

8. Cryptocities Index ? 👀  - data is collected from the SteadyMarketplace NFT floor price

9. CPI are based on these 8 main categories
    - FoodAndBeverages,
    - Housing,
    - Apparel,
    - Transportation,
    - EducationAndCommunication,
    - OtherGoodsAndServices,
    - Recreation,
    - MedicalCare

10. To comply with the gov : "maybe" might need to do something like how paypal does with its stablecoin - freeze, unfreeze, wipeFronzenAddress functionality (admin only) 

11. For erc721 and erc1155 minting/burning etc - we going to need to have separate smart contracts for it 
    - using IPFS to host the assets (image, metadata) 
    - and then the address of the smart contract will then saved in the vendor - collectionAddress + description of the collection
        - if this is the case, then the collectionTotalSales will comes from the erc721 and erc1155 smart contracts itself
Q: can we skip this part and directly implement it in the marketplace smart contract ?

12. Judging from the Addresses we have on SteadyMarketplace contract,
    - vendorAddress - The address of the vendor's wallet @ msgSender
    - collectionAddress - The address of the vendor's collection
    - contractAddress - The address of the NFT contract
Q: collectionAddress and contractAddress can be the same?

13. calculation of CPI and IR - https://www.investopedia.com/terms/c/consumerpriceindex.asp with new category (only 8 category w/ enum)


14. IMPORTANT: we need people to spend their money on the marketplace w/ STC token
    - one shall need to convert any ERC20 Token Such as ETH, MATIC etc to STC via uniswap
        - need to have some "collateral features" upon swapping the token
    - the marketplace only accept STC token

15. Depending on the product category, the NFT shall be subject to burning upon completion of the sale transaction. 
    - For instance, in the case of the Food and Beverage (FnB) category, the NFT corresponding to the purchase shall be burned upon successful delivery of the ordered food or drinks from the cafe to the customer. 
    - However, in the context of the Housing category for eg, the NFT will not undergo the burning process, as it represents a long-term ownership of a property.


16. Also, we also need to measure the CPI based on their `weight` - to be sync w/ the world's CPI category weight
    - These are CPI Categories by Weight as of July 2023 based on investopedia 
    | Group            | Weight   |
    |------------------|----------|
    | Housing          | 34.7%    |
    | Food             | 13.4%    |
    | Transportation   | 5.9%     |
    | Commodities      | 21.3%    |
    | Health Care      | 6.4%     |
    | Energy           | 7.0%     |
    | Education        | 4.8%     |
    | Other Expenses   | 6.5%     |
    | Total Expenses   | 100%     |

17. Reason on why we need `VENDOR_FEE` - ONE TIME FEE per wallet address
    - **Infrastructure Enhancement:**
    The vendor fee can be allocated towards improving the overall infrastructure of the marketplace. This includes investing in better server resources, load balancing, and optimizing the platform's performance to ensure smooth and uninterrupted user experience. Improved infrastructure leads to faster response times, higher availability, and better scalability, making the platform more reliable and attractive to both vendors and buyers.

    - **Security and Compliance Measures:**
    The vendor fee can be utilized to enhance the platform's security and compliance measures. This could involve funding regular security audits, penetration testing, and vulnerability assessments to identify and address potential vulnerabilities. Additionally, the fee could support compliance with data protection regulations and industry standards, ensuring the protection of sensitive user information and maintaining trust in the platform's security practices.

    - **Innovation and Feature Development:**
    The fee can be directed towards continuous innovation and the development of new features that enhance the marketplace's functionality and user experience. This could include the implementation of advanced search and recommendation algorithms, integration with emerging technologies like blockchain for improved transparency, and the creation of user-friendly mobile applications. Investing in innovation helps the platform stay competitive and provides users with compelling reasons to choose and stay on the marketplace.