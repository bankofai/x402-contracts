// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaymentPermit} from "../interface/IPaymentPermit.sol";

library PermitHash {
    bytes32 public constant PERMIT_META_TYPEHASH = keccak256("PermitMeta(uint8 kind,bytes16 paymentId,uint256 nonce,uint256 validAfter,uint256 validBefore)");
    bytes32 public constant PAYMENT_TYPEHASH = keccak256("Payment(address payToken,uint256 maxPayAmount,address payTo)");
    bytes32 public constant FEE_TYPEHASH = keccak256("Fee(address feeTo,uint256 feeAmount)");
    bytes32 public constant DELIVERY_TYPEHASH = keccak256("Delivery(address receiveToken,uint256 miniReceiveAmount,uint256 tokenId)");
    
    // Sort referenced structs alphabetically: Delivery, Fee, Payment, PermitMeta
    bytes32 public constant PAYMENT_PERMIT_DETAILS_TYPEHASH = keccak256(
        "PaymentPermitDetails(PermitMeta meta,address caller,Payment payment,Fee fee,Delivery delivery)Delivery(address receiveToken,uint256 miniReceiveAmount,uint256 tokenId)Fee(address feeTo,uint256 feeAmount)Payment(address payToken,uint256 maxPayAmount,address payTo)PermitMeta(uint8 kind,bytes16 paymentId,uint256 nonce,uint256 validAfter,uint256 validBefore)"
    );

    bytes32 public constant CALLBACK_DETAILS_TYPEHASH = keccak256("CallbackDetails(address callbackTarget,bytes callbackData)");

    // Sort structs: CallbackDetails, Delivery, Fee, Payment, PaymentPermitDetails, PermitMeta
    bytes32 public constant PAYMENT_PERMIT_WITH_CALLBACK_TYPEHASH = keccak256(
        "PaymentPermitWithCallback(PaymentPermitDetails permit,CallbackDetails callback)CallbackDetails(address callbackTarget,bytes callbackData)Delivery(address receiveToken,uint256 miniReceiveAmount,uint256 tokenId)Fee(address feeTo,uint256 feeAmount)Payment(address payToken,uint256 maxPayAmount,address payTo)PaymentPermitDetails(PermitMeta meta,address caller,Payment payment,Fee fee,Delivery delivery)PermitMeta(uint8 kind,bytes16 paymentId,uint256 nonce,uint256 validAfter,uint256 validBefore)"
    );

    function hash(IPaymentPermit.PaymentPermitDetails memory permit) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PAYMENT_PERMIT_DETAILS_TYPEHASH,
            hash(permit.meta),
            permit.caller,
            hash(permit.payment),
            hash(permit.fee),
            hash(permit.delivery)
        ));
    }

    function hash(IPaymentPermit.CallbackDetails memory callback) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CALLBACK_DETAILS_TYPEHASH,
            callback.callbackTarget,
            keccak256(callback.callbackData)
        ));
    }

    function hash(IPaymentPermit.PermitMeta memory meta) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PERMIT_META_TYPEHASH,
            meta.kind,
            meta.paymentId,
            meta.nonce,
            meta.validAfter,
            meta.validBefore
        ));
    }

    function hash(IPaymentPermit.Payment memory payment) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PAYMENT_TYPEHASH,
            payment.payToken,
            payment.maxPayAmount,
            payment.payTo
        ));
    }

    function hash(IPaymentPermit.Fee memory fee) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FEE_TYPEHASH,
            fee.feeTo,
            fee.feeAmount
        ));
    }

    function hash(IPaymentPermit.Delivery memory delivery) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            DELIVERY_TYPEHASH,
            delivery.receiveToken,
            delivery.miniReceiveAmount,
            delivery.tokenId
        ));
    }
}
