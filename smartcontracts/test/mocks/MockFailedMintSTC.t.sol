// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockFailedMintSTC is ERC20Burnable, Ownable {
    error SteadyCoin__AmountMustBeMoreThanZero();
    error SteadyCoin__BurnAmountExceedsBalance();
    error SteadyCoin__NotZeroAddress();

    constructor() ERC20("SteadyCoin", "STC") {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert SteadyCoin__AmountMustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert SteadyCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert SteadyCoin__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert SteadyCoin__AmountMustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return false;
    }
}
