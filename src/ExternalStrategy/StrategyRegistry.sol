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

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract StrategyRegistry is Ownable {
    /// @notice  0 mean unregistered others will be detemined by the External Strategy Council
    mapping(address => uint256) private _strategyFlags;

    function setStrategyFlags(address libAddress, uint256 _flags)
        public
        onlyOwner
    {
        _strategyFlags[libAddress] = _flags;
    }

    function getStrategyFlags(address libAddress)
        public
        view
        returns (uint256)
    {
        return _strategyFlags[libAddress];
    }

    function isRegistered(address libAddress) public view returns (bool) {
        return _strategyFlags[libAddress] >= 1;
    }
}