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
}
