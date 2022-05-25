// Copyright (C) 2022 Exponent

// This file is part of Exponent.

// Exponent is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Exponent is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Exponent.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.1;

/// @title SushiStrategyLib Contract
/// @author Exponent team

import "../ExternalStrategy/ExternalStrategyBase.sol";
import "./IMiniSushi.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SushiStrategyLib is ExternalStrategyBase {
    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20;

    // token pair
    address token1;
    address token2;

    // asset to sell on automate()
    address[] autoSellList;

    // poolID to stake
    uint256 poolID;

    // allow automation
    bool allowAutomate;
    // bounty for automate() caller. in BIP
    uint256 bounty;

    address constant rounter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // polygon sushi rounter
    address constant chef = 0x0769fd68dFb93167989C6f7254cd0D766Fb2841F; // polygon sushi minichef

    address immutable weth;
    address immutable factory;
    address liqToken;

    constructor() {
        weth = IRouter(rounter).WETH();
        factory = IRouter(rounter).factory();
    }

    /// @notice harvest -> sell -> LP -> stake -> send bounty to caller
    function automate() public override {
        require(allowAutomate, "not allow automation");
        uint256[] memory pendingBounty = new uint256[](autoSellList.length);

        IChef(chef).harvest(poolID, address(this));
        for (uint256 i = 0; i < autoSellList.length; i++) {
            uint256 bal = IERC20(autoSellList[i]).balanceOf(address(this));
            pendingBounty[i] = (bal * bounty) / 10_000;
            _sellSplit(autoSellList[i], (bal * (10_000 - bounty)) / 10_000);
        }
        _processLiquidity();
        _stake();

        for (uint256 i = 0; i < autoSellList.length; i++) {
            ERC20(autoSellList[i]).safeTransfer(msg.sender, pendingBounty[i]);
        }
    }

    /// @dev Enter position. split asset -> LP -> stake.
    function __Enter(bytes memory actionArgs) internal override {
        (address token, uint256 amount) = abi.decode(
            actionArgs,
            (address, uint256)
        );
        _sellSplit(token, amount);
        _processLiquidity();
        _stake();
    }

    /// @dev reduce position. unstake -> remove LP. will "not" return asset to vault
    function __Reduce(bytes memory actionArgs) internal override {
        uint256 unstake = abi.decode(actionArgs, (uint256));
        IChef(chef).withdrawAndHarvest(poolID, unstake, address(this));
        uint256 bal = IERC20(liqToken).balanceOf(address(this));
        IERC20(liqToken).approve(rounter, bal);
        IRouter(rounter).removeLiquidity(
            token1,
            token2,
            bal,
            0,
            0,
            address(this),
            block.timestamp + 100
        );
        /// @dev will not return asset to vault
    }

    /// @dev config param. -- token1, token2, autoSellList, poolID,allowAutomate,bounty in order
    function __Config(bytes memory actionArgs) internal override {
        (token1, token2, autoSellList, poolID, allowAutomate, bounty) = abi
            .decode(
                actionArgs,
                (address, address, address[], uint256, bool, uint256)
            );

        liqToken = IFactory(factory).getPair(token1, token2);
    }

    /// @dev no special function
    function __AdminExecute(bytes memory actionArgs) internal pure override {
        revert("not available");
    }

    ////////////////////
    // POSITION VALUE //
    ////////////////////

    /// @notice Retrieves the debt assets (negative value) of the external position
    /// @return assets_ Debt assets
    /// @return amounts_ Debt asset amounts
    function getDebtAssets()
        external
        view
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        /// @dev no debt
    }

    /// @notice Retrieves the managed assets (positive value) of the external position
    /// @return assets_ Managed assets
    /// @return amounts_ Managed asset amounts
    function getManagedAssets()
        external
        view
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        assets_ = new address[](2);
        amounts_ = new uint256[](2);

        assets_[0] = IPair(liqToken).token0();
        assets_[1] = IPair(liqToken).token1();

        uint256 total = IPair(liqToken).totalSupply();
        uint256 contractLP = IPair(liqToken).balanceOf(address(this));
        (uint256 r1, uint256 r2, ) = IPair(liqToken).getReserves();
        amounts_[0] =
            (r1 * contractLP) /
            total +
            ERC20(assets_[0]).balanceOf(address(this));
        amounts_[1] =
            (r2 * contractLP) /
            total +
            ERC20(assets_[1]).balanceOf(address(this));
    }

    /////////////
    // Parser  //
    /////////////

    function parseEnter(bytes memory encodedArg)
        external
        view
        override
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        )
    {
        (address token, uint256 amount) = abi.decode(
            encodedArg,
            (address, uint256)
        );
        assetsToTransfer_ = new address[](1);
        assetsToTransfer_[0] = token;
        amountsToTransfer_ = new uint256[](1);
        amountsToTransfer_[0] = amount;
    }

    function parseReduce(bytes memory encodedArg)
        external
        view
        override
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        )
    {}

    function parseAdminExecute(bytes memory encodedArg)
        external
        view
        override
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        )
    {
        revert("not available");
    }

    /// internal function

    function _sellSplit(address token, uint256 amount) internal {
        IERC20(token).approve(rounter, amount);

        if (token != token1) {
            IRouter(rounter).swapExactTokensForTokens(
                amount / 2,
                0,
                buildPath(token, token1),
                address(this),
                block.timestamp + 100
            );
        }
        if (token != token2) {
            IRouter(rounter).swapExactTokensForTokens(
                amount / 2,
                0,
                buildPath(token, token2),
                address(this),
                block.timestamp + 100
            );
        }
    }

    function _processLiquidity() internal {
        uint256 t1Bal = ERC20(token1).balanceOf(address(this));
        uint256 t2Bal = ERC20(token2).balanceOf(address(this));

        IERC20(token1).approve(rounter, t1Bal);
        IERC20(token2).approve(rounter, t2Bal);
        IRouter(rounter).addLiquidity(
            token1,
            token2,
            t1Bal,
            t2Bal,
            0,
            0,
            address(this),
            block.timestamp + 100
        );
    }

    function buildPath(address tin, address tout)
        internal
        view
        returns (address[] memory path)
    {
        path = new address[](3);
        path[0] = tin;
        path[1] = weth;
        path[2] = tout;
    }

    function _stake() public {
        uint256 bal = IERC20(liqToken).balanceOf(address(this));
        IERC20(liqToken).approve(chef, bal);
        IChef(chef).deposit(poolID, bal, address(this));
    }
}
