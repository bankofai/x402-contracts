// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IEIP712} from "./IEIP712.sol";

interface IPaymentPermit is IEIP712 {
    struct PaymentPermitDetails {
        PermitMeta meta;
        address buyer;
        address caller;
        Payment payment;
        Fee fee;
    }

    struct PermitMeta {
        uint8 kind; // 0: PAYMENT_ONLY
        bytes16 paymentId;
        uint256 nonce;
        uint256 validAfter;
        uint256 validBefore;
    }

    struct Payment {
        address payToken;
        uint256 payAmount;
        address payTo;
    }

    struct Fee {
        address feeTo;
        uint256 feeAmount;
    }

    // Events
    event PermitTransfer(
        address indexed buyer,
        bytes16 indexed paymentId,
        address indexed payToken,
        address payTo,
        uint256 amount
    );

    // Errors
    error InvalidTimestamp();
    error InvalidCaller();
    error InvalidNonce();
    error InvalidSignature();
    error NonceAlreadyUsed();
    error InvalidKind();
    error BuyerMismatch();

    // Functions
    function permitTransferFrom(
        PaymentPermitDetails calldata permit,
        address owner,
        bytes calldata signature
    ) external;

    function nonceBitmap(
        address owner,
        uint256 wordPos
    ) external view returns (uint256);

    function nonceUsed(
        address owner,
        uint256 nonce
    ) external view returns (bool);
}
