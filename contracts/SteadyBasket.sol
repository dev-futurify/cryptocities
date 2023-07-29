// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*
 * @title SteadyBasket
 @ description A dynamic NFT smart contract which acts as a "baskets" of good and services in the ecosystem.
 * @author ricogustavo
 * @team Futurify x EpicStartups
 *
 */
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SteadyBasket is ERC1155, ERC1155Burnable, Ownable {
    error SteadyBasket__AmountMustBeMoreThanZero();
    error SteadyBasket__BurnAmountExceedsBalance();
    error SteadyBasket__NotZeroAddress();
    error SteadyBasket__AddressesAndAmountsMustBeEqualLength();

    constructor() ERC1155("ipfs://") {}

    function burn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) public override onlyOwner {
        uint256 balance = balanceOf(_account, _id);
        if (_amount <= 0) {
            revert SteadyBasket__AmountMustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert SteadyBasket__BurnAmountExceedsBalance();
        }
        super.burn(_account, _id, _amount);
    }

    function burnBatch(
        address[] memory _accounts,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public onlyOwner {
        if (
            _accounts.length != _ids.length ||
            _accounts.length != _amounts.length
        ) {
            revert SteadyBasket__AddressesAndAmountsMustBeEqualLength();
        }
        for (uint256 i = 0; i < _accounts.length; i++) {
            burn(_accounts[i], _ids[i], _amounts[i]);
        }
    }

    function mint(
        address _account,
        uint256 _id,
        uint256 _amount
    ) public onlyOwner returns (bool) {
        if (_account == address(0)) {
            revert SteadyBasket__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert SteadyBasket__AmountMustBeMoreThanZero();
        }
        _mint(_account, _id, _amount, "");
        return true;
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }
}
