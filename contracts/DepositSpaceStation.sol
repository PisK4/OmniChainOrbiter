// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDepositSpaceStation} from "./interface/IDepositSpaceStation.sol";
import {Errors} from "./library/Errors.sol";

/// the DepositSpaceStation is a contract that user can deposit eth to become a validator
/// anyone can deposit eth to become a validator, the minimal deposit is 32 eth
/// validator can withdraw eth after the withdraw delay time
/// validator will get reward after they validate the cross-chain message & response to Relayer in time
/// the profit will store in the spare merkle tree, the proctol will update the merkle tree root after a period of time
contract DepositSpaceStation is IDepositSpaceStation, Ownable {
    uint256 private immutable MINIMAL_DEPOSIT_HARDCODE = 32 ether;
    uint256 private _minimalDeposit = MINIMAL_DEPOSIT_HARDCODE;

    uint64 private immutable MINIMAL_WITHDRAW_DELAY_HARDCODE = 7 days;
    uint64 private immutable MAXIMAL_WITHDRAW_DELAY_HARDCODE = 30 days;

    // invalid merkle tree root
    bytes32 private immutable INVALID_SMT_ROOT = bytes32(uint256(1));

    /// @dev withdraw delay time, determine how long the validator can withdraw eth after they request withdraw
    uint64 private _withdrawDelay = MINIMAL_WITHDRAW_DELAY_HARDCODE;
    /// @dev submitter is the address that submit the merkle tree root
    address public submitter;
    /// @dev spare merkle tree root
    bytes32 public smtRoot = INVALID_SMT_ROOT;

    /// @dev validator List
    mapping(address => bool) public validators;
    /// @dev withdraw request list
    mapping(address => uint64) private _withdrawRequestList;

    /// @notice incase of validator transfer eth to the deposit contract directly by mistake
    ///         we will check the value of all the transaction which contains the eth
    ///         if the value is greater than the minimal deposit, we will register the validator
    receive() external payable {
        // if (msg.value >= _minimalDeposit) {
        // _register();
        // }
    }

    constructor() payable Ownable(msg.sender) {
        submitter = owner();
    }

    modifier onlyValidator() {
        // if (validators[msg.sender] != true) {
        //     revert Errors.AccessDenied();
        // }
        _;
    }

    modifier onlySubmitter() {
        if (msg.sender != submitter) {
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

    function submitSmtRoot(bytes32 root) external override onlySubmitter {
        _changeNewSmtRoot(root);
    }

    function _changeNewSmtRoot(bytes32 root) internal {
        smtRoot = root;
    }

    /// @notice call this function to register as a validator, the minimal deposit is 32 eth
    function register() external payable override {
        if (msg.value < _minimalDeposit) {
            revert Errors.ValueNotMatched();
        }
        // _register();
    }

    function _register() internal {
        validators[msg.sender] = true;
        emit Register(msg.sender, 0);
    }

    /// @notice if you want to withdraw eth, you need to call this function to request withdraw
    ///        after the withdraw delay time, you can call the withdraw function to withdraw eth
    function withdrawRequest() external onlyValidator {
        uint64 targetWithdrawTime = uint64(block.timestamp) + _withdrawDelay;
        _withdrawRequestList[msg.sender] = targetWithdrawTime;
        emit WithdarwRequest(msg.sender, targetWithdrawTime);
    }

    /// @notice once the withdraw delay time is reached, you can call this function to withdraw eth
    function withdarw(
        bytes32[] calldata proof,
        uint256 amount
    ) external override onlyValidator {
        if (smtRoot == INVALID_SMT_ROOT) {
            revert Errors.RootNotSubmitted();
        }

        if (_withdrawRequestList[msg.sender] > uint64(block.timestamp)) {
            revert Errors.TimeNotReached();
        }
        _withdrawRequestList[msg.sender] = 0;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));

        if (verifySmtRoot(proof, leaf) != true) {
            revert Errors.VerifyFailed();
        }

        _changeNewSmtRoot(INVALID_SMT_ROOT);

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
