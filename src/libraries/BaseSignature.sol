// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {MessageHashUtils} from "@oz/utils/cryptography/MessageHashUtils.sol";

library BaseSignature {
    // Helper function to get the signed hash.
    function getEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        return MessageHashUtils.toEthSignedMessageHash(keccak256(abi.encode(hash)));
    }
}
