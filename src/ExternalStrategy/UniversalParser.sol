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

import "../IExternalPositionParser.sol";
import "./ExternalStrategyBase.sol";
pragma solidity ^0.8.1;

/// @title UniversalParser - universal parser.
/// @author Exponent team
/// @notice Parser for XPernalPosition series
contract UniversalParser is IExternalPositionParser {
    /// @notice Parses the assets to send and receive for the callOnExternalPosition
    /// @param _externalPosition The _externalPosition to be called
    /// @param _actionId The _actionId for the callOnExternalPosition
    /// @param _encodedActionArgs The encoded parameters for the callOnExternalPosition
    /// @return assetsToTransfer_ The assets to be transferred from the Vault
    /// @return amountsToTransfer_ The amounts to be transferred from the Vault
    /// @return assetsToReceive_ The assets to be received at the Vault
    function parseAssetsForAction(
        address _externalPosition,
        uint256 _actionId,
        bytes memory _encodedActionArgs
    )
        external
        view
        override
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        )
    {
        if (_actionId == uint256(ExternalStrategyBase.Actions.Enter)) {
            (
                assetsToTransfer_,
                amountsToTransfer_,
                assetsToReceive_
            ) = ExternalStrategyBase(_externalPosition).parseEnter(
                _encodedActionArgs
            );
        } else if (_actionId == uint256(ExternalStrategyBase.Actions.Reduce)) {
            (
                assetsToTransfer_,
                amountsToTransfer_,
                assetsToReceive_
            ) = ExternalStrategyBase(_externalPosition).parseReduce(
                _encodedActionArgs
            );
        } else if (
            _actionId == uint256(ExternalStrategyBase.Actions.AdminExecute)
        ) {
            (
                assetsToTransfer_,
                amountsToTransfer_,
                assetsToReceive_
            ) = ExternalStrategyBase(_externalPosition).parseAdminExecute(
                _encodedActionArgs
            );
        } else if (
            _actionId == uint256(ExternalStrategyBase.Actions.AdminWithdraw)
        ) {
            // fixed interface
            (address[] memory _asset, ) = abi.decode(
                _encodedActionArgs,
                (address[], uint256[])
            );
            assetsToReceive_ = _asset;
        } else if (_actionId == uint256(ExternalStrategyBase.Actions.Config)) {
            // no action on config
        } else {
            revert("receiveCallFromVault: Invalid actionId");
        }

        return (assetsToTransfer_, amountsToTransfer_, assetsToReceive_);
    }

    /// @notice Parse and validate input arguments to be used when initializing a newly-deployed ExternalPositionProxy
    /// @dev Empty for this external position type
    function parseInitArgs(address, bytes memory)
        external
        override
        returns (bytes memory)
    {}
}
