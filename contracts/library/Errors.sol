// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Errors {
    error NonceNotMatched();
    error NotTrustedSequencer();
    error StationPaused();
    error WithdrawError();
    error OutOfGas();
    error ValueNotMatched();
}
