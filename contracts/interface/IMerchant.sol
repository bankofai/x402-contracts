// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaymentPermit} from "./IPaymentPermit.sol";

interface IMerchant {
    /**
     * @dev Simple settle function
     * @param permit The payment permit details
     * @param signature The signature from the buyer
     */
    function settle(IPaymentPermit.PaymentPermitDetails calldata permit, bytes calldata signature) external;

    /**
     * @dev Settle function with merchant data and signature
     * @param permit The payment permit details
     * @param merchantData data from merchant
     * @param signature The signature from the buyer
     * @param merchantSignature The signature from the merchant
     */
    function settle(
        IPaymentPermit.PaymentPermitDetails calldata permit, 
        bytes calldata merchantData, 
        bytes calldata signature, 
        bytes calldata merchantSignature
    ) external;
}
