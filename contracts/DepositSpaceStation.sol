// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDepositSpaceStation} from "./interface/IDepositSpaceStation.sol";
import {Errors} from "./library/Errors.sol";

contract DepositSpaceStation is IDepositSpaceStation, Ownable {
    uint256 private immutable MINIMAL_DEPOSIT_HARDCODE = 32 ether;
    uint256 private _minimalDeposit = MINIMAL_DEPOSIT_HARDCODE;

    uint64 private immutable MINIMAL_WITHDRAW_DELAY_HARDCODE = 7 days;
    uint64 private immutable MAXIMAL_WITHDRAW_DELAY_HARDCODE = 30 days;
    uint64 private _withdrawDelay = MINIMAL_WITHDRAW_DELAY_HARDCODE;

    address public submitter;
    bytes public smtRoot;

    /// @dev validator List
    mapping(address => bool) public validators;
    /// @dev withdraw request list
    mapping(address => uint64) private _withdrawRequestList;

    receive() external payable {
        if (msg.value >= _minimalDeposit) {
            _register();
        }
    }

    constructor() payable Ownable(msg.sender) {
        submitter = owner();
    }

    modifier onlyValidator() {
        if (validators[msg.sender] != true) {
            revert Errors.AccessDenied();
        }
        _;
    }

    function setMinimalDeposit(uint256 amount) external override onlyOwner {
        if (amount >= MINIMAL_DEPOSIT_HARDCODE) {
            _minimalDeposit = amount;
        }
    }

    function fetchMinimalDeposit() external view override returns (uint256) {
        return _minimalDeposit;
    }

    function setMinimalWithdrawDelay(
        uint64 delaySeconds
    ) external override onlyOwner {
        if (
            delaySeconds >= MINIMAL_WITHDRAW_DELAY_HARDCODE &&
            delaySeconds <= MAXIMAL_WITHDRAW_DELAY_HARDCODE
        ) {
            _withdrawDelay = delaySeconds;
        }
    }

    function fetchMinimalWithdrawDelay()
        external
        view
        override
        returns (uint64)
    {
        return _withdrawDelay;
    }

    function setSubmitter(address newSubmitter) external override onlyOwner {
        if (newSubmitter == address(0)) {
            revert Errors.InvalidAddress();
        }
        submitter = newSubmitter;
    }

    function register() external payable override {
        if (msg.value < _minimalDeposit) {
            revert Errors.ValueNotMatched();
        }
        _register();
    }

    function _register() internal {
        validators[msg.sender] = true;
        emit Register(msg.sender, 0);
    }

    function withdrawRequest() external onlyValidator {
        uint64 targetWithdrawTime = uint64(block.timestamp) + _withdrawDelay;
        _withdrawRequestList[msg.sender] = targetWithdrawTime;
        emit WithdarwRequest(msg.sender, targetWithdrawTime);
    }

    function withdarw(
        bytes32[] calldata proof,
        bytes32 leaf
    ) external override onlyValidator {
        if (_withdrawRequestList[msg.sender] > uint64(block.timestamp)) {
            revert Errors.TimeNotReached();
        }
        _withdrawRequestList[msg.sender] = 0;

        if (verifySmtRoot(proof, leaf) != true) {
            revert Errors.VerifyFailed();
        }

        uint256 amount = 0;

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        if (!sent) {
            revert Errors.WithdrawError();
        }

        emit Withdarw(msg.sender);
    }

    function verifySmtRoot(
        bytes32[] calldata proof,
        bytes32 leaf
    ) internal pure returns (bool) {
        (proof, leaf);
        // TODO: verify smt root
        return true;
    }
}
