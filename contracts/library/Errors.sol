// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Errors {
    error NonceNotMatched();
    error StationPaused();
    error WithdrawError();
    error OutOfGas();
    error ValueNotMatched();
    error AccessDenied();
    error TimeNotReached();
    error VerifyFailed();
    error InvalidAddress();
}
