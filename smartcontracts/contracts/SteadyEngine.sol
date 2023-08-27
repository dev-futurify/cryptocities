// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*
 * @title SteadyEngine
 * @description This contract is the core of the SteadyCoin system. It handles all the logic
 * for minting and redeeming STC, airdrops, as well as depositing and withdrawing based on
 * consumer price index and inflation rate sourced from the Steady Marketplace contract.
 * @author ricogustavo
 * @team Futurify x EpicStartups
 *
 */

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SteadyCoin} from "./SteadyCoin.sol";
import {SteadyMarketplace} from "./SteadyMarketplace.sol";

interface ISteadyFormula {
    function getYearlyCPI() external view returns (uint256);

    function getYearlyInflationRate() external view returns (uint256);
}

contract SteadyEngine is ReentrancyGuard {
    error SteadyEngine__OnlyOwner();
    error SteadyEngine__NeedsMoreThanZero();
    error SteadyEngine__TokenNotAllowed(address token);
    error SteadyEngine__TransferFailed();
    error SteadyEngine__BreaksHealthFactor(uint256 healthFactorValue);
    error SteadyEngine__MintFailed();
    error SteadyEngine__HealthFactorOk();
    error SteadyEngine__HealthFactorNotImproved();

    SteadyCoin private immutable i_stc;
    SteadyMarketplace private immutable i_marketplace;
    ISteadyFormula private i_formula;

    uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means we need to be 200% over-collateralized
    uint256 private constant LIQUIDATION_BONUS = 10; // This means we get assets at a 10% discount when liquidating
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant FEED_PRECISION = 1e8;

    /// @dev Mapping of token address to price feed address
    mapping(address collateralToken => address priceFeed) private s_priceFeeds;
    /// @dev Amount of collateral deposited by user
    mapping(address user => mapping(address collateralToken => uint256 amount))
        private s_collateralDeposited;
    /// @dev Amount of STC minted by user
    mapping(address user => uint256 amount) private s_STCMinted;
    /// @dev If we know exactly how many tokens we have, we could make this immutable!
    address[] private s_collateralTokens;

    event CollateralDeposited(
        address indexed user,
        address indexed token,
        uint256 indexed amount
    );
    event CollateralRedeemed(
        address indexed redeemFrom,
        address indexed redeemTo,
        address token,
        uint256 amount
    ); // if redeemFrom != redeemedTo, then it was liquidated

    modifier onlyOwner() {
        if (msg.sender != i_marketplace.owner()) {
            revert SteadyEngine__OnlyOwner();
        }
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert SteadyEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert SteadyEngine__TokenNotAllowed(token);
        }
        _;
    }

    constructor(
        address stcAddress,
        address steadyMarketplaceAddress,
        address steadyFormulaAddress
    ) {
        i_stc = SteadyCoin(stcAddress);
        i_marketplace = SteadyMarketplace(steadyMarketplaceAddress);
        i_formula = ISteadyFormula(steadyFormulaAddress);
    }

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral we're depositing
     * @param amountCollateral: The amount of collateral we're depositing
     * @param amountStcToMint: The amount of STC we want to mint
     * @notice This function will deposit your collateral and mint STC in one transaction
     */
    function depositCollateralAndMintStc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountStcToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintStc(amountStcToMint);
    }

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral we're depositing
     * @param amountCollateral: The amount of collateral we're depositing
     * @param amountStcToBurn: The amount of STC we want to burn
     * @notice This function will withdraw your collateral and burn STC in one transaction
     */
    function redeemCollateralForStc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountStcToBurn
    ) external moreThanZero(amountCollateral) {
        _burnStc(amountStcToBurn, msg.sender, msg.sender);
        _redeemCollateral(
            tokenCollateralAddress,
            amountCollateral,
            msg.sender,
            msg.sender
        );
        revertIfHealthFactorIsBroken(msg.sender);
    }

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral we're redeeming
     * @param amountCollateral: The amount of collateral we're redeeming
     * @notice This function will redeem your collateral.
     * @notice If we have STC minted, we will not be able to redeem until we burn your STC
     */
    function redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    ) external moreThanZero(amountCollateral) nonReentrant {
        _redeemCollateral(
            tokenCollateralAddress,
            amountCollateral,
            msg.sender,
            msg.sender
        );
        revertIfHealthFactorIsBroken(msg.sender);
    }

    /*
     * @notice careful! You'll burn your STC here! Make sure we want to do this...
     * @dev we might want to use this if we're nervous we might get liquidated and want to just burn
     * we STC but keep your collateral in.
     */
    function burnStc(uint256 amount) external moreThanZero(amount) {
        _burnStc(amount, msg.sender, msg.sender);
        revertIfHealthFactorIsBroken(msg.sender); // I don't think this would ever hit...
    }

    /*
     * @param amountStcToMint: The amount of STC we want to mint
     * You can only mint STC if we hav enough collateral
     */
    function mintStc(
        uint256 amountStcToMint
    ) public moreThanZero(amountStcToMint) nonReentrant {
        s_STCMinted[msg.sender] += amountStcToMint;
        revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_stc.mint(msg.sender, amountStcToMint);

        if (minted != true) {
            revert SteadyEngine__MintFailed();
        }
    }

    /*
     * @param recipients: The addresses of the recipients of the airdrop
     * @param amounts: The amounts of STC to airdrop to each recipient
     * @notice This function will mint STC and transfer to the recipients
     * when Inflation Rate threshold are met.
     */
    function airdropStc(
        address[] memory recipients,
        uint256[] memory amounts
    ) external nonReentrant {
        // mint the STC and transfer to the receipients
        for (uint256 i = 0; i < recipients.length; i++) {
            s_STCMinted[recipients[i]] += amounts[i];
            bool success = i_stc.mint(recipients[i], amounts[i]);
            if (!success) {
                revert SteadyEngine__MintFailed();
            }
        }
    }

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral we're depositing
     * @param amountCollateral: The amount of collateral we're depositing
     */
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        public
        moreThanZero(amountCollateral)
        nonReentrant
        isAllowedToken(tokenCollateralAddress)
    {
        s_collateralDeposited[msg.sender][
            tokenCollateralAddress
        ] += amountCollateral;
        emit CollateralDeposited(
            msg.sender,
            tokenCollateralAddress,
            amountCollateral
        );
        bool success = IERC20(tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            amountCollateral
        );
        if (!success) {
            revert SteadyEngine__TransferFailed();
        }
    }

    function _redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        address from,
        address to
    ) private {
        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(
            from,
            to,
            tokenCollateralAddress,
            amountCollateral
        );
        bool success = IERC20(tokenCollateralAddress).transfer(
            to,
            amountCollateral
        );
        if (!success) {
            revert SteadyEngine__TransferFailed();
        }
    }

    function _burnStc(
        uint256 amountStcToBurn,
        address onBehalfOf,
        address stcFrom
    ) private {
        s_STCMinted[onBehalfOf] -= amountStcToBurn;

        bool success = i_stc.transferFrom(
            stcFrom,
            address(this),
            amountStcToBurn
        );
        // This conditional is hypothetically unreachable
        if (!success) {
            revert SteadyEngine__TransferFailed();
        }
        i_stc.burn(amountStcToBurn);
    }

    function _getAccountInformation(
        address user
    ) private view returns (uint256 totalDscMinted, uint256 collateralValue) {
        totalDscMinted = s_STCMinted[user];
        collateralValue = getAccountCollateralValue(user);
    }

    function _healthFactor(address user) private view returns (uint256) {
        (
            uint256 totalDscMinted,
            uint256 collateralValue
        ) = _getAccountInformation(user);
        return _calculateHealthFactor(totalDscMinted, collateralValue);
    }

    function _calculateHealthFactor(
        uint256 totalDscMinted,
        uint256 collateralValue
    ) internal pure returns (uint256) {
        if (totalDscMinted == 0) return type(uint256).max;
        uint256 collateralAdjustedForThreshold = (collateralValue *
            LIQUIDATION_THRESHOLD) / 100;
        return (collateralAdjustedForThreshold * 1e18) / totalDscMinted;
    }

    function _getYearlyCPI() private view returns (uint256) {
        return i_formula.getYearlyCPI();
    }

    function _getYearlyInflationRate() private view returns (uint256) {
        return i_formula.getYearlyInflationRate();
    }

    function revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert SteadyEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    function calculateHealthFactor(
        uint256 totalDscMinted,
        uint256 collateralValue
    ) external pure returns (uint256) {
        return _calculateHealthFactor(totalDscMinted, collateralValue);
    }

    function getAccountInformation(
        address user
    ) external view returns (uint256 totalDscMinted, uint256 collateralValue) {
        return _getAccountInformation(user);
    }

    function getCollateralBalanceOfUser(
        address user,
        address token
    ) external view returns (uint256) {
        return s_collateralDeposited[user][token];
    }

    function getAccountCollateralValue(
        address user
    ) public view returns (uint256 totalCollateralValue) {
        for (uint256 index = 0; index < s_collateralTokens.length; index++) {
            address token = s_collateralTokens[index];
            uint256 amount = s_collateralDeposited[user][token];
            uint256 cpiChange = _getYearlyCPI();
            uint256 inflationRate = _getYearlyInflationRate();
            uint256 adjustedCollateralValue = (((amount * (100 + cpiChange)) /
                100) * (100 + inflationRate)) / 100;
            totalCollateralValue += adjustedCollateralValue;
        }
        return totalCollateralValue;
    }

    // change the contract address of the formula and only the owner can call this function
    function changeFormulaAddress(address newAddress) external onlyOwner {
        i_formula = ISteadyFormula(newAddress);
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    function getAdditionalFeedPrecision() external pure returns (uint256) {
        return ADDITIONAL_FEED_PRECISION;
    }

    function getLiquidationThreshold() external pure returns (uint256) {
        return LIQUIDATION_THRESHOLD;
    }

    function getLiquidationBonus() external pure returns (uint256) {
        return LIQUIDATION_BONUS;
    }

    function getMinHealthFactor() external pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }

    function getCollateralTokens() external view returns (address[] memory) {
        return s_collateralTokens;
    }

    function getStc() external view returns (address) {
        return address(i_stc);
    }

    function getCollateralTokenPriceFeed(
        address token
    ) external view returns (address) {
        return s_priceFeeds[token];
    }

    function getHealthFactor(address user) external view returns (uint256) {
        return _healthFactor(user);
    }
}
