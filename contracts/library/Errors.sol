// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Errors {
    error NonceNotMatched();
    error StationPaused();
    error WithdrawError();
    error OutOfGas();
    error ValueNotMatched();
    error AccessDenied();
    error RootNotSubmitted();
    error TimeNotReached();
    error VerifyFailed();
    error InvalidAddress();
    error InvalidMessage();
    error DuplicatedValue();
    error ArrivalTimeNotMakeSense();
    error LandingPadOccupied();
    error SimulateResult(bool[] results);
    error NotImplement();
    error SetupError();
    error ExcuteError(bytes32 messageId);
}
