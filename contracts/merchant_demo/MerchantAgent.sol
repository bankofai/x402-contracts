// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAgentExecInterface} from "../interface/IAgentExecInterface.sol";
import {IPaymentPermit} from "../interface/IPaymentPermit.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "sun-contract-std/libraries/SafeTransferLib.sol";

contract MerchantAgent is IAgentExecInterface {

    address public owner;

    event DataExecuted(address token, uint256 amount);
    event Withdrawn(address token, uint256 amount);

    error NotOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            SafeTransferLib.safeTransferETH(msg.sender, amount);
        } else {
            require(SafeTransferLib.safeTransfer(token, msg.sender, amount), "Withdraw failed");
        }
        emit Withdrawn(token, amount);
    }

    function Execute(bytes calldata data) external override {
        // TODO: check msg.sender
        
        (address buyer, IPaymentPermit.Delivery memory delivery) = abi.decode(data, (address, IPaymentPermit.Delivery));
        
        if (delivery.receiveToken != address(0) && delivery.miniReceiveAmount > 0) {
            require(SafeTransferLib.safeTransfer(delivery.receiveToken, buyer, delivery.miniReceiveAmount), "Delivery failed");
        }

        emit DataExecuted(delivery.receiveToken, delivery.miniReceiveAmount);
    }
}
