// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IEIP712} from "./interface/IEIP712.sol";
import {IPaymentPermit} from "./interface/IPaymentPermit.sol";

abstract contract EIP712 is IEIP712 {
    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The EIP-712 domain typeHash.
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 internal constant _DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

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

    /*//////////////////////////////////////////////////////////////////////////
                                   IMMUTABLES
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 internal immutable _DOMAIN_SEPARATOR;

    function DOMAIN_SEPARATOR() public view virtual override returns (bytes32) {
        return _DOMAIN_SEPARATOR;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(string memory name, string memory version) {
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Returns the digest to sign.
    function _hashTypedData(bytes32 structHash) internal view virtual returns (bytes32 digest) {
        return keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, structHash));
    }

    function _buildDigest(IPaymentPermit.PaymentPermitDetails calldata permit) internal view returns (bytes32) {
        return _hashTypedData(_hashPaymentPermitDetails(permit));
    }

    function _buildDigestWithCallback(IPaymentPermit.PaymentPermitDetails calldata permit, IPaymentPermit.CallbackDetails calldata callback) internal view returns (bytes32) {
        return _hashTypedData(keccak256(abi.encode(
            PAYMENT_PERMIT_WITH_CALLBACK_TYPEHASH,
            _hashPaymentPermitDetails(permit),
            _hashCallbackDetails(callback)
        )));
    }

    function _hashPaymentPermitDetails(IPaymentPermit.PaymentPermitDetails calldata permit) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PAYMENT_PERMIT_DETAILS_TYPEHASH,
            _hashPermitMeta(permit.meta),
            permit.caller,
            _hashPayment(permit.payment),
            _hashFee(permit.fee),
            _hashDelivery(permit.delivery)
        ));
    }

    function _hashCallbackDetails(IPaymentPermit.CallbackDetails calldata callback) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CALLBACK_DETAILS_TYPEHASH,
            callback.callbackTarget,
            keccak256(callback.callbackData)
        ));
    }

    function _hashPermitMeta(IPaymentPermit.PermitMeta calldata meta) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PERMIT_META_TYPEHASH,
            meta.kind,
            meta.paymentId,
            meta.nonce,
            meta.validAfter,
            meta.validBefore
        ));
    }

    function _hashPayment(IPaymentPermit.Payment calldata payment) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PAYMENT_TYPEHASH,
            payment.payToken,
            payment.maxPayAmount,
            payment.payTo
        ));
    }

    function _hashFee(IPaymentPermit.Fee calldata fee) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FEE_TYPEHASH,
            fee.feeTo,
            fee.feeAmount
        ));
    }

    function _hashDelivery(IPaymentPermit.Delivery calldata delivery) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            DELIVERY_TYPEHASH,
            delivery.receiveToken,
            delivery.miniReceiveAmount,
            delivery.tokenId
        ));
    }
}
