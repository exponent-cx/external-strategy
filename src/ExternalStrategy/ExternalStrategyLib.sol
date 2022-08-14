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

import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/contracts/utils/StorageSlot.sol";
import "./StrategyRegistry.sol";
import "../IExternalPosition.sol";

contract ExternalStrategyLib is Initializable {
    /// @dev keccak256 of "Fennec's spot!" :)
    bytes32 private constant _Strategy_LIB_ADDRESS_SLOT =
        0x7337df092c0316084d76a4326136350931be81e811e39e9a6a73eff5aa1555eb;

    StrategyRegistry public immutable strategyRegistry;

    constructor(address _registry) {
        strategyRegistry = StrategyRegistry(_registry);
    }

    receive() external payable {}

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address contractLogic = _getImplementation();
        require(contractLogic != address(0));

        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }

    /// @dev This version of ExternalStrategyLib only operate registered strategy
    function init(bytes calldata args) public initializer {
        (address lib, bytes memory strategyInitArgs) = abi.decode(
            args,
            (address, bytes)
        );
        require(strategyRegistry.isRegistered(lib));

        _setImplementation(lib);
        (bool success, ) = lib.delegatecall(
            abi.encodeWithSelector(
                IExternalPosition.init.selector,
                strategyInitArgs
            )
        );
        require(success);
    }

    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_Strategy_LIB_ADDRESS_SLOT).value;
    }

    function _setImplementation(address newImplementation) private {
        StorageSlot
            .getAddressSlot(_Strategy_LIB_ADDRESS_SLOT)
            .value = newImplementation;
    }
}