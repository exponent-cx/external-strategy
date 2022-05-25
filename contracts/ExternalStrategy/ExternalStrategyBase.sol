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

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../IExternalPosition.sol";

/// @title ExternalStrategyBase
/// @author Exponent team

contract ExternalStrategyBase is IExternalPosition {
    using SafeERC20 for IERC20;
    enum Actions {
        Enter,
        Reduce,
        Config,
        AdminExecute,
        AdminWithdraw
    }

    constructor() {}

    /// @notice Initializes the external position
    /// @dev We don't do that here
    function init(bytes memory) external override {}

    /// @notice Receives and executes a call from the Vault
    /// @param _actionData Encoded data to execute the action
    function receiveCallFromVault(bytes memory _actionData) external override {
        (uint256 actionId, bytes memory actionArgs) = abi.decode(
            _actionData,
            (uint256, bytes)
        );
        if (actionId == uint256(Actions.Enter)) {
            __Enter(actionArgs);
        } else if (actionId == uint256(Actions.Reduce)) {
            __Reduce(actionArgs);
        } else if (actionId == uint256(Actions.Config)) {
            __Config(actionArgs);
        } else if (actionId == uint256(Actions.AdminExecute)) {
            __AdminExecute(actionArgs);
        } else if (actionId == uint256(Actions.AdminWithdraw)) {
            __AdminWithdraw(actionArgs);
        } else {
            revert("receiveCallFromVault: Invalid actionId");
        }
    }

    /// @notice public function use to automate.
    function automate() public virtual {}

    /// @dev Enter position.
    function __Enter(bytes memory actionArgs) internal virtual {}

    /// @dev reduce position. (return asset to vault is optional)
    function __Reduce(bytes memory actionArgs) internal virtual {}

    /// @dev config param.
    function __Config(bytes memory actionArgs) internal virtual {}

    /// @dev special function
    function __AdminExecute(bytes memory actionArgs) internal virtual {}

    /// @dev Return any asset to vault.
    function __AdminWithdraw(bytes memory actionArgs) internal {
        (address[] memory tokens, uint256[] memory amounts) = abi.decode(
            actionArgs,
            (address[], uint256[])
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeTransfer(msg.sender, amounts[i]);
        }
    }

    ////////////////////
    // POSITION VALUE //
    ////////////////////

    /// @notice Retrieves the debt assets (negative value) of the external position
    /// @return assets_ Debt assets
    /// @return amounts_ Debt asset amounts
    function getDebtAssets()
        external
        virtual
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {}

    /// @notice Retrieves the managed assets (positive value) of the external position
    /// @return assets_ Managed assets
    /// @return amounts_ Managed asset amounts
    function getManagedAssets()
        external
        virtual
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {}

    /////////////
    // Parser  //
    /////////////
    function parseEnter(bytes memory encodedArg)
        external
        view
        virtual
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        )
    {}

    function parseReduce(bytes memory encodedArg)
        external
        view
        virtual
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        )
    {}

    function parseAdminExecute(bytes memory encodedArg)
        external
        view
        virtual
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        )
    {}
}
