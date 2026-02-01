// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaymentPermit} from "./interface/IPaymentPermit.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "sun-contract-std/libraries/SafeTransferLib.sol";
import {EIP712} from "./EIP712.sol";
import {IAgentExecInterface} from "./interface/IAgentExecInterface.sol";
import {PermitHash} from "./libraries/PermitHash.sol";

contract PaymentPermit is IPaymentPermit, EIP712 {
    using PermitHash for IPaymentPermit.PaymentPermitDetails;
    using PermitHash for IPaymentPermit.CallbackDetails;

    mapping(address => mapping(uint256 => uint256)) public override nonceBitmap;

    constructor() EIP712() {}

    function permitTransferFrom(
        PaymentPermitDetails calldata permit, 
        TransferDetails calldata transferDetails, 
        address owner,
        bytes calldata signature
    ) external override {
        if (owner != permit.buyer) revert BuyerMismatch();
        if (permit.meta.kind != 0) revert InvalidKind();
        if (block.timestamp < permit.meta.validAfter || block.timestamp > permit.meta.validBefore) revert InvalidTimestamp();
        if (permit.caller != address(0) && msg.sender != permit.caller) revert InvalidCaller();
        if (transferDetails.amount > permit.payment.maxPayAmount) revert InvalidAmount();

        _useNonce(owner, permit.meta.nonce);

        bytes32 digest = _hashTypedData(permit.hash());
        if (!_verifySignature(owner, digest, signature)) revert InvalidSignature();

        // Execute transfers
        // 1. Payment
        require(SafeTransferLib.safeTransferFrom(permit.payment.payToken, owner, permit.payment.payTo, transferDetails.amount), "Payment failed");

        // 2. Fee
        if (permit.fee.feeAmount > 0) {
            require(SafeTransferLib.safeTransferFrom(permit.payment.payToken, owner, permit.fee.feeTo, permit.fee.feeAmount), "Fee failed");
        }

        emit PermitTransfer(owner, permit.meta.paymentId, transferDetails.amount);
    }

    function permitTransferFromWithCallback(
        PaymentPermitDetails calldata permit,
        CallbackDetails calldata callbackDetails, 
        TransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external override {
        if (owner != permit.buyer) revert BuyerMismatch();
        if (permit.meta.kind != 1) revert InvalidKind();
        if (block.timestamp < permit.meta.validAfter || block.timestamp > permit.meta.validBefore) revert InvalidTimestamp();
        if (permit.caller != address(0) && msg.sender != permit.caller) revert InvalidCaller();
        if (transferDetails.amount > permit.payment.maxPayAmount) revert InvalidAmount();
        
        _useNonce(owner, permit.meta.nonce);

        bytes32 digest = _hashTypedData(permit.hash());
        if (!_verifySignature(owner, digest, signature)) revert InvalidSignature();

        // Execute transfers
        // 1. Payment
        require(SafeTransferLib.safeTransferFrom(permit.payment.payToken, owner, permit.payment.payTo, transferDetails.amount), "Payment failed");

        // 2. Fee
        if (permit.fee.feeAmount > 0) {
            require(SafeTransferLib.safeTransferFrom(permit.payment.payToken, owner, permit.fee.feeTo, permit.fee.feeAmount), "Fee failed");
        }

        // 3. Callback
        uint256 balanceBefore = 0;
        if (permit.delivery.miniReceiveAmount > 0) {
            balanceBefore = ERC20(permit.delivery.receiveToken).balanceOf(owner);
        }

        if (callbackDetails.callbackTarget != address(0)) {
            IAgentExecInterface(callbackDetails.callbackTarget).Execute(callbackDetails.callbackData);
        }

        if (permit.delivery.miniReceiveAmount > 0) {
            uint256 balanceAfter = ERC20(permit.delivery.receiveToken).balanceOf(owner);
            if (balanceAfter < balanceBefore || (balanceAfter - balanceBefore) < permit.delivery.miniReceiveAmount) {
                revert InvalidDelivery();
            }
        }

        emit PermitTransfer(owner, permit.meta.paymentId, transferDetails.amount);
    }

    function nonceUsed(address owner, uint256 nonce) public view override returns (bool) {
        uint256 wordPos = nonce >> 8;
        uint256 bitPos = nonce & 0xff;
        uint256 word = nonceBitmap[owner][wordPos];
        return (word & (1 << bitPos)) != 0;
    }

    function _useNonce(address owner, uint256 nonce) internal {
        uint256 wordPos = nonce >> 8;
        uint256 bitPos = nonce & 0xff;
        uint256 word = nonceBitmap[owner][wordPos];
        uint256 mask = 1 << bitPos;
        if ((word & mask) != 0) revert NonceAlreadyUsed();
        nonceBitmap[owner][wordPos] = word | mask;
    }
    
    function _verifySignature(address signer, bytes32 digest, bytes memory signature) internal pure returns (bool) {
        if (signature.length != 65) return false;
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        address recovered = ecrecover(digest, v, r, s);
        return recovered != address(0) && recovered == signer;
    }
}
