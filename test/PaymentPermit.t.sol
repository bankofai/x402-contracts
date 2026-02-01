// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/PaymentPermit.sol";
import "./MockERC20.sol";
import "../contracts/interface/IPaymentPermit.sol";
import "../contracts/interface/IAgentExecInterface.sol";
import "../contracts/libraries/PermitHash.sol";

contract MockAgent is IAgentExecInterface {
    event Executed(bytes data);
    function Execute(bytes calldata data) external override {
        if (data.length > 0) {
            (address token, address to, uint256 amount) = abi.decode(data, (address, address, uint256));
            MockERC20(token).transfer(to, amount);
        }
        emit Executed(data);
    }
}

contract PaymentPermitTest is Test {
    using PermitHash for IPaymentPermit.PaymentPermitDetails;
    using PermitHash for IPaymentPermit.CallbackDetails;

    PaymentPermit public paymentPermit;
    MockERC20 public token;

    uint256 internal ownerPrivateKey;
    address internal owner;
    address internal receiver;
    address internal feeReceiver;
    MockAgent internal agent;

    bytes32 internal DOMAIN_SEPARATOR;

    // TypeHashes from library
    bytes32 public constant PERMIT_META_TYPEHASH = PermitHash.PERMIT_META_TYPEHASH;
    bytes32 public constant PAYMENT_TYPEHASH = PermitHash.PAYMENT_TYPEHASH;
    bytes32 public constant FEE_TYPEHASH = PermitHash.FEE_TYPEHASH;
    bytes32 public constant DELIVERY_TYPEHASH = PermitHash.DELIVERY_TYPEHASH;
    bytes32 public constant PAYMENT_PERMIT_DETAILS_TYPEHASH = PermitHash.PAYMENT_PERMIT_DETAILS_TYPEHASH;
    bytes32 public constant CALLBACK_DETAILS_TYPEHASH = PermitHash.CALLBACK_DETAILS_TYPEHASH;

    function setUp() public {
        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);
        receiver = address(0xB0B);
        feeReceiver = address(0xFEE);

        paymentPermit = new PaymentPermit();
        token = new MockERC20("Test Token", "TEST", 18);
        agent = new MockAgent();
        
        DOMAIN_SEPARATOR = paymentPermit.DOMAIN_SEPARATOR();

        token.mint(owner, 1000 ether);
        token.mint(address(agent), 1000 ether);
        
        vm.prank(owner);
        token.approve(address(paymentPermit), type(uint256).max);
    }

    function testPermitTransferFrom() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(100 ether, 1 ether);
        bytes memory signature = _signPermit(permit);
        
        IPaymentPermit.TransferDetails memory transferDetails = IPaymentPermit.TransferDetails({
            amount: 50 ether // Transfer less than max
        });

        vm.prank(address(0xCA11EB)); // Arbitrary caller
        paymentPermit.permitTransferFrom(permit, transferDetails, owner, signature);

        assertEq(token.balanceOf(owner), 1000 ether - 50 ether - 1 ether);
        assertEq(token.balanceOf(receiver), 50 ether);
        assertEq(token.balanceOf(feeReceiver), 1 ether);
        
        assertTrue(paymentPermit.nonceUsed(owner, permit.meta.nonce));
    }

    function testRevertNonceUsed() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(100 ether, 0);
        bytes memory signature = _signPermit(permit);
        
        IPaymentPermit.TransferDetails memory transferDetails = IPaymentPermit.TransferDetails(100 ether);

        paymentPermit.permitTransferFrom(permit, transferDetails, owner, signature);
        
        vm.expectRevert(IPaymentPermit.NonceAlreadyUsed.selector);
        paymentPermit.permitTransferFrom(permit, transferDetails, owner, signature);
    }

    function testRevertExpired() public {
         IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(100 ether, 0);
         permit.meta.validBefore = block.timestamp - 1;
         
         bytes memory signature = _signPermit(permit);
                  vm.expectRevert(IPaymentPermit.InvalidTimestamp.selector);
          paymentPermit.permitTransferFrom(permit, IPaymentPermit.TransferDetails(100 ether), owner, signature);
    }

    function testRevertSignatureError() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(100 ether, 0);
        bytes memory signature = _signPermit(permit);
        
        // Tamper with data
        permit.payment.maxPayAmount = 200 ether;

        vm.expectRevert(IPaymentPermit.InvalidSignature.selector);
        paymentPermit.permitTransferFrom(permit, IPaymentPermit.TransferDetails(100 ether), owner, signature);
    }

    function testRevertBuyerMismatch() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(100 ether, 0);
        bytes memory signature = _signPermit(permit);
        
        vm.expectRevert(IPaymentPermit.BuyerMismatch.selector);
        paymentPermit.permitTransferFrom(permit, IPaymentPermit.TransferDetails(100 ether), address(0xDEAD), signature);
    }

    function testRevertInvalidKind_Normal() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(100 ether, 0);
        permit.meta.kind = 1; // Wrong kind for normal transfer
        bytes memory signature = _signPermit(permit);
        
        vm.expectRevert(IPaymentPermit.InvalidKind.selector);
        paymentPermit.permitTransferFrom(permit, IPaymentPermit.TransferDetails(100 ether), owner, signature);
    }

    function testRevertInvalidKind_WithCallback() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(100 ether, 0);
        permit.meta.kind = 0; // Wrong kind for callback transfer
        
        IPaymentPermit.CallbackDetails memory callback = IPaymentPermit.CallbackDetails({
            callbackTarget: address(agent),
            callbackData: hex""
        });
        
        bytes memory signature = _signPermitWithCallback(permit, callback);
        
        vm.expectRevert(IPaymentPermit.InvalidKind.selector);
        paymentPermit.permitTransferFromWithCallback(permit, callback, IPaymentPermit.TransferDetails(100 ether), owner, signature);
    }

    function testPermitTransferFromWithCallback() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(100 ether, 1 ether);
        permit.meta.kind = 1;
        IPaymentPermit.CallbackDetails memory callback = IPaymentPermit.CallbackDetails({
            callbackTarget: address(agent),
            callbackData: hex""
        });
        
        bytes memory signature = _signPermitWithCallback(permit, callback);
        
        IPaymentPermit.TransferDetails memory transferDetails = IPaymentPermit.TransferDetails({
            amount: 50 ether
        });

        vm.prank(address(0xCA11EB));
        
        // vm.expectEmit(true, true, true, true);
        // emit MockAgent.Executed(hex"");
        
        paymentPermit.permitTransferFromWithCallback(permit, callback, transferDetails, owner, signature);

        assertEq(token.balanceOf(owner), 1000 ether - 50 ether - 1 ether);
        assertEq(token.balanceOf(receiver), 50 ether);
        assertEq(token.balanceOf(feeReceiver), 1 ether);
        
        assertTrue(paymentPermit.nonceUsed(owner, permit.meta.nonce));
    }

    function testPermitTransferFromWithCallback_DeliverySuccess() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(100 ether, 1 ether);
        permit.meta.kind = 1;
        
        // Setup delivery expectation
        permit.delivery.receiveToken = address(token);
        permit.delivery.miniReceiveAmount = 10 ether;
        
        // Callback data to tell agent to transfer tokens back to owner
        bytes memory callbackData = abi.encode(address(token), owner, 10 ether);

        IPaymentPermit.CallbackDetails memory callback = IPaymentPermit.CallbackDetails({
            callbackTarget: address(agent),
            callbackData: callbackData
        });
        
        bytes memory signature = _signPermitWithCallback(permit, callback);
        
        IPaymentPermit.TransferDetails memory transferDetails = IPaymentPermit.TransferDetails({
            amount: 50 ether
        });

        vm.prank(address(0xCA11EB));
        paymentPermit.permitTransferFromWithCallback(permit, callback, transferDetails, owner, signature);

        // Owner paid 51, received 10. Net change = -51 + 10 = -41
        // Initial: 1000. Final: 1000 - 50 - 1 + 10 = 959
        assertEq(token.balanceOf(owner), 959 ether);
    }
    
    function testPermitTransferFromWithCallback_DeliveryFail() public {
        IPaymentPermit.PaymentPermitDetails memory permit = _createPermit(100 ether, 1 ether);
        permit.meta.kind = 1;
        
        // Setup delivery expectation
        permit.delivery.receiveToken = address(token);
        permit.delivery.miniReceiveAmount = 10 ether;
        
        // Callback data that does NOT transfer tokens
        bytes memory callbackData = hex""; 

        IPaymentPermit.CallbackDetails memory callback = IPaymentPermit.CallbackDetails({
            callbackTarget: address(agent),
            callbackData: callbackData
        });
        
        bytes memory signature = _signPermitWithCallback(permit, callback);
        
        IPaymentPermit.TransferDetails memory transferDetails = IPaymentPermit.TransferDetails({
            amount: 50 ether
        });

        vm.prank(address(0xCA11EB));
        vm.expectRevert(IPaymentPermit.InvalidDelivery.selector);
        paymentPermit.permitTransferFromWithCallback(permit, callback, transferDetails, owner, signature);
    }
    
    // Helpers
    function _createPermit(uint256 amount, uint256 fee) internal view returns (IPaymentPermit.PaymentPermitDetails memory) {
        return IPaymentPermit.PaymentPermitDetails({
            meta: IPaymentPermit.PermitMeta({
                kind: 0,
                paymentId: bytes16(0),
                nonce: 0,
                validAfter: 0,
                validBefore: block.timestamp + 1000
            }),
            buyer: owner,
            caller: address(0),
            payment: IPaymentPermit.Payment({
                payToken: address(token),
                maxPayAmount: amount,
                payTo: receiver
            }),
            fee: IPaymentPermit.Fee({
                feeTo: feeReceiver,
                feeAmount: fee
            }),
            delivery: IPaymentPermit.Delivery({
                receiveToken: address(0),
                miniReceiveAmount: 0,
                tokenId: 0
            })
        });
    }

    function _signPermit(IPaymentPermit.PaymentPermitDetails memory permit) internal view returns (bytes memory) {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            permit.hash()
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        return abi.encodePacked(r, s, v);
    }

    function _signPermitWithCallback(IPaymentPermit.PaymentPermitDetails memory permit, IPaymentPermit.CallbackDetails memory /*callback*/) internal view returns (bytes memory) {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            permit.hash()
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        return abi.encodePacked(r, s, v);
    }
}
