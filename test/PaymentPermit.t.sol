// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/PaymentPermit.sol";
import "./MockERC20.sol";
import "../contracts/interface/IPaymentPermit.sol";
import "../contracts/libraries/PermitHash.sol";

contract PaymentPermitTest is Test {
    using PermitHash for IPaymentPermit.PaymentPermitDetails;

    PaymentPermit public paymentPermit;
    MockERC20 public token;

    uint256 internal ownerPrivateKey;
    address internal owner;
    address internal receiver;
    address internal feeReceiver;

    bytes32 internal DOMAIN_SEPARATOR;

    // TypeHashes from library
    bytes32 public constant PERMIT_META_TYPEHASH =
        PermitHash.PERMIT_META_TYPEHASH;
    bytes32 public constant PAYMENT_TYPEHASH = PermitHash.PAYMENT_TYPEHASH;
    bytes32 public constant FEE_TYPEHASH = PermitHash.FEE_TYPEHASH;
    bytes32 public constant PAYMENT_PERMIT_DETAILS_TYPEHASH =
        PermitHash.PAYMENT_PERMIT_DETAILS_TYPEHASH;

    function setUp() public {
        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);
        receiver = address(0xB0B);
        feeReceiver = address(0xFEE);

        paymentPermit = new PaymentPermit();
        token = new MockERC20("Test Token", "TEST", 18);

        DOMAIN_SEPARATOR = paymentPermit.DOMAIN_SEPARATOR();

        token.mint(owner, 1000 ether);

        vm.prank(owner);
        token.approve(address(paymentPermit), type(uint256).max);
    }

    function testPermitTransferEvent() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(
            100 ether,
            1 ether,
            address(this)
        );
        bytes memory signature = _signPermit(permit);

        vm.expectEmit(true, true, true, true);
        emit IPaymentPermit.PermitTransfer(
            owner,
            permit.meta.paymentId,
            address(token),
            receiver,
            100 ether
        );

        paymentPermit.permitTransferFrom(permit, owner, signature);
    }
    function testPermitTransferFrom() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(
            100 ether,
            1 ether,
            address(0xCA11EB)
        );
        bytes memory signature = _signPermit(permit);

        vm.prank(address(0xCA11EB)); // Arbitrary caller
        paymentPermit.permitTransferFrom(permit, owner, signature);

        assertEq(token.balanceOf(owner), 1000 ether - 100 ether - 1 ether);
        assertEq(token.balanceOf(receiver), 100 ether);
        assertEq(token.balanceOf(feeReceiver), 1 ether);

        assertTrue(paymentPermit.nonceUsed(owner, permit.meta.nonce));
    }

    function testRevertNonceUsed() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(
            100 ether,
            0,
            address(this)
        );
        bytes memory signature = _signPermit(permit);

        paymentPermit.permitTransferFrom(permit, owner, signature);

        vm.expectRevert(IPaymentPermit.NonceAlreadyUsed.selector);
        paymentPermit.permitTransferFrom(permit, owner, signature);
    }

    function testRevertExpired() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(
            100 ether,
            0,
            address(this)
        );
        permit.meta.validBefore = block.timestamp - 1;

        bytes memory signature = _signPermit(permit);
        vm.expectRevert(IPaymentPermit.InvalidTimestamp.selector);
        paymentPermit.permitTransferFrom(permit, owner, signature);
    }

    function testRevertSignatureError() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(
            100 ether,
            0,
            address(this)
        );
        bytes memory signature = _signPermit(permit);

        // Tamper with data
        permit.payment.payAmount = 200 ether;

        vm.expectRevert(IPaymentPermit.InvalidSignature.selector);
        paymentPermit.permitTransferFrom(permit, owner, signature);
    }

    function testRevertBuyerMismatch() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(
            100 ether,
            0,
            address(this)
        );
        bytes memory signature = _signPermit(permit);

        vm.expectRevert(IPaymentPermit.BuyerMismatch.selector);
        paymentPermit.permitTransferFrom(permit, address(0xDEAD), signature);
    }

    function testRevertInvalidKind_Normal() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(
            100 ether,
            0,
            address(this)
        );
        permit.meta.kind = 1; // Wrong kind for normal transfer
        bytes memory signature = _signPermit(permit);

        vm.expectRevert(IPaymentPermit.InvalidKind.selector);
        paymentPermit.permitTransferFrom(permit, owner, signature);
    }

    function testRevertInvalidCaller() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(
            100 ether,
            0,
            address(this)
        );
        bytes memory signature = _signPermit(permit);

        vm.prank(address(0xBAD));
        vm.expectRevert(IPaymentPermit.InvalidCaller.selector);
        paymentPermit.permitTransferFrom(permit, owner, signature);
    }

    function testRevertNotYetValid() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(
            100 ether,
            0,
            address(this)
        );
        permit.meta.validAfter = block.timestamp + 10;
        bytes memory signature = _signPermit(permit);

        vm.expectRevert(IPaymentPermit.InvalidTimestamp.selector);
        paymentPermit.permitTransferFrom(permit, owner, signature);
    }

    function testZeroFee() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(
            100 ether,
            0, // Zero fee
            address(this)
        );
        bytes memory signature = _signPermit(permit);

        paymentPermit.permitTransferFrom(permit, owner, signature);

        assertEq(token.balanceOf(owner), 1000 ether - 100 ether);
        assertEq(token.balanceOf(receiver), 100 ether);
        assertEq(token.balanceOf(feeReceiver), 0);
    }

    function testPaymentTransferFailed() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(
            100 ether,
            0,
            address(this)
        );
        bytes memory signature = _signPermit(permit);

        // Mock transferFrom to return false for payment
        vm.mockCall(
            address(token),
            abi.encodeWithSelector(
                token.transferFrom.selector,
                owner,
                receiver,
                100 ether
            ),
            abi.encode(false)
        );

        vm.expectRevert("Payment failed");
        paymentPermit.permitTransferFrom(permit, owner, signature);
    }

    function testFeeTransferFailed() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(
            100 ether,
            1 ether,
            address(this)
        );
        bytes memory signature = _signPermit(permit);

        // Mock transferFrom to return false for fee
        vm.mockCall(
            address(token),
            abi.encodeWithSelector(
                token.transferFrom.selector,
                owner,
                feeReceiver,
                1 ether
            ),
            abi.encode(false)
        );

        vm.expectRevert("Fee failed");
        paymentPermit.permitTransferFrom(permit, owner, signature);
    }

    // Helpers
    function _createPermit(
        uint256 amount,
        uint256 fee,
        address caller
    ) internal view returns (IPaymentPermit.PaymentPermitDetails memory) {
        return
            IPaymentPermit.PaymentPermitDetails({
                meta: IPaymentPermit.PermitMeta({
                    kind: 0,
                    paymentId: bytes16(0),
                    nonce: 0,
                    validAfter: 0,
                    validBefore: block.timestamp + 1000
                }),
                buyer: owner,
                caller: caller,
                payment: IPaymentPermit.Payment({
                    payToken: address(token),
                    payAmount: amount,
                    payTo: receiver
                }),
                fee: IPaymentPermit.Fee({feeTo: feeReceiver, feeAmount: fee})
            });
    }

    function _signPermit(
        IPaymentPermit.PaymentPermitDetails memory permit
    ) internal view returns (bytes memory) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, permit.hash())
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        return abi.encodePacked(r, s, v);
    }
}
