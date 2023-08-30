//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ISuperToken.sol";

interface ISquareSuperToken is ISuperToken {
    function squareWithdraw(address account, uint256 amount) external;

    function upgradeTo(
        address to,
        uint256 amount,
        bytes calldata data
    ) external;

    function approve(address spender, uint256 amount) external returns (bool);

    function emitTransfer(address account) external;
}
