// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMerchant} from "../interface/IMerchant.sol";
import {IPaymentPermit} from "../interface/IPaymentPermit.sol";

contract Merchant is IMerchant {
    IPaymentPermit public immutable paymentPermit;
    address public immutable agent;

    constructor(address _paymentPermit, address _agent) {
        paymentPermit = IPaymentPermit(_paymentPermit);
        agent = _agent;
    }

    /// @inheritdoc IMerchant
    function settle(IPaymentPermit.PaymentPermitDetails calldata permit, bytes calldata signature) external override {
        IPaymentPermit.TransferDetails memory transferDetails = IPaymentPermit.TransferDetails({
            amount: permit.payment.maxPayAmount
        });

        IPaymentPermit.CallbackDetails memory callbackDetails = IPaymentPermit.CallbackDetails({
            callbackTarget: agent,
            callbackData: abi.encode(permit.buyer, permit.delivery)
        });

        paymentPermit.permitTransferFromWithCallback(permit, callbackDetails, transferDetails, permit.buyer, signature);
    }

    /// @inheritdoc IMerchant
    function settle(
        IPaymentPermit.PaymentPermitDetails calldata permit,
        bytes calldata merchantData,
        bytes calldata signature,
        bytes calldata merchantSignature
    ) external override {
        // Here you might want to verify merchantSignature if merchantData is sensitive
        // For now, we just proceed with the payment transfer
        
        IPaymentPermit.TransferDetails memory transferDetails = IPaymentPermit.TransferDetails({
            amount: permit.payment.maxPayAmount
        });

        IPaymentPermit.CallbackDetails memory callbackDetails = IPaymentPermit.CallbackDetails({
            callbackTarget: agent,
            callbackData: abi.encode(permit.buyer, permit.delivery)
        });

        paymentPermit.permitTransferFromWithCallback(permit, callbackDetails, transferDetails, permit.buyer, signature);
    }
}
