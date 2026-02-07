// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaymentPermit} from "../interface/IPaymentPermit.sol";

library PermitHash {
    bytes32 public constant PERMIT_META_TYPEHASH =
        keccak256(
            "PermitMeta(uint8 kind,bytes16 paymentId,uint256 nonce,uint256 validAfter,uint256 validBefore)"
        );
    bytes32 public constant PAYMENT_TYPEHASH =
        keccak256("Payment(address payToken,uint256 payAmount,address payTo)");
    bytes32 public constant FEE_TYPEHASH =
        keccak256("Fee(address feeTo,uint256 feeAmount)");

    // Sort referenced structs alphabetically: Fee, Payment, PermitMeta
    bytes32 public constant PAYMENT_PERMIT_DETAILS_TYPEHASH =
        keccak256(
            "PaymentPermitDetails(PermitMeta meta,address buyer,address caller,Payment payment,Fee fee)Fee(address feeTo,uint256 feeAmount)Payment(address payToken,uint256 payAmount,address payTo)PermitMeta(uint8 kind,bytes16 paymentId,uint256 nonce,uint256 validAfter,uint256 validBefore)"
        );

    function hash(
        IPaymentPermit.PaymentPermitDetails memory permit
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PAYMENT_PERMIT_DETAILS_TYPEHASH,
                    hash(permit.meta),
                    permit.buyer,
                    permit.caller,
                    hash(permit.payment),
                    hash(permit.fee)
                )
            );
    }

    function hash(
        IPaymentPermit.PermitMeta memory meta
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PERMIT_META_TYPEHASH,
                    meta.kind,
                    meta.paymentId,
                    meta.nonce,
                    meta.validAfter,
                    meta.validBefore
                )
            );
    }

    function hash(
        IPaymentPermit.Payment memory payment
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PAYMENT_TYPEHASH,
                    payment.payToken,
                    payment.payAmount,
                    payment.payTo
                )
            );
    }

    function hash(
        IPaymentPermit.Fee memory fee
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(FEE_TYPEHASH, fee.feeTo, fee.feeAmount));
    }
}
