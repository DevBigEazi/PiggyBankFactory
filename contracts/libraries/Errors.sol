// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

library Errors {
    // custom erros
    error AlreadyWithdrawnAll();
    error NotOwner();
    error AddressZeroDetected();
    error OnlyUSDTDAIandUSDCisAllowed();
    error NoEnoughBalanceToWithdraw();
    error NotYetTime();
}