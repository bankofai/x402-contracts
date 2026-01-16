// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/merchant_demo/Merchant.sol";
import "../contracts/merchant_demo/MerchantAgent.sol";
import "../contracts/PaymentPermit.sol";
import "./MockERC20.sol";
import "../contracts/interface/IPaymentPermit.sol";
import "../contracts/libraries/PermitHash.sol";

contract MerchantTest is Test {
    using PermitHash for IPaymentPermit.PaymentPermitDetails;

    Merchant public merchant;
    PaymentPermit public paymentPermit;
    MockERC20 public token;
    MockERC20 public deliveryToken;
    MerchantAgent public merchantAgent;

    uint256 internal ownerPrivateKey;
    address internal owner;
    address internal receiver;
    address internal feeReceiver;

    receive() external payable {}

    function setUp() public {
        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);
        receiver = address(0x123);
        feeReceiver = address(0x456);

        paymentPermit = new PaymentPermit();
        merchantAgent = new MerchantAgent();
        merchant = new Merchant(address(paymentPermit), address(merchantAgent));
        token = new MockERC20("Test Token", "TEST", 18);
        deliveryToken = new MockERC20("Delivery Token", "DLV", 18);

        token.mint(owner, 1000 ether);
        deliveryToken.mint(address(merchantAgent), 1000 ether);

        vm.prank(owner);
        token.approve(address(paymentPermit), type(uint256).max);
    }

    function testMerchantSettle() public {
        uint256 amount = 100 ether;
        uint256 deliveryAmount = 50 ether;

        IPaymentPermit.PaymentPermitDetails memory permit = IPaymentPermit.PaymentPermitDetails({
            meta: IPaymentPermit.PermitMeta({
                kind: 1, // Must be 1 for callback interface
                paymentId: bytes16(0),
                nonce: 0,
                validAfter: 0,
                validBefore: block.timestamp + 1000
            }),
            buyer: owner,
            caller: address(merchant), // Set caller to merchant address
            payment: IPaymentPermit.Payment({
                payToken: address(token),
                maxPayAmount: amount,
                payTo: receiver
            }),
            fee: IPaymentPermit.Fee({
                feeTo: feeReceiver,
                feeAmount: 1 ether
            }),
            delivery: IPaymentPermit.Delivery({
                receiveToken: address(deliveryToken),
                miniReceiveAmount: deliveryAmount,
                tokenId: 0
            })
        });

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            paymentPermit.DOMAIN_SEPARATOR(),
            permit.hash()
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, true, true, address(merchantAgent));
        emit MerchantAgent.DataExecuted(address(deliveryToken), deliveryAmount);
        
        merchant.settle(permit, signature);

        assertEq(token.balanceOf(owner), 1000 ether - 100 ether - 1 ether);
        assertEq(token.balanceOf(receiver), 100 ether);
        assertEq(token.balanceOf(feeReceiver), 1 ether);
        assertEq(deliveryToken.balanceOf(owner), deliveryAmount);
    }

    function testWithdrawal() public {
        uint256 withdrawAmount = 10 ether;
        
        // ERC20 withdrawal
        uint256 balanceBefore = deliveryToken.balanceOf(address(this));
        merchantAgent.withdraw(address(deliveryToken), withdrawAmount);
        assertEq(deliveryToken.balanceOf(address(this)), balanceBefore + withdrawAmount);

        // Native (TRX/ETH) withdrawal
        vm.deal(address(merchantAgent), 10 ether);
        uint256 ethBalanceBefore = address(this).balance;
        merchantAgent.withdraw(address(0), 5 ether);
        assertEq(address(this).balance, ethBalanceBefore + 5 ether);

        // Non-owner revert
        vm.prank(owner);
        vm.expectRevert(MerchantAgent.NotOwner.selector);
        merchantAgent.withdraw(address(deliveryToken), 1 ether);
    }
}
