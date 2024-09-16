// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {Network} from "test/util/Network.sol";

import {ClaimToken} from "src/ClaimToken.sol";

contract ClaimTokenDeploy is Script {
    ClaimToken claimToken;

    address deployer = vm.rememberKey(vm.envUint("DEPLOYER_PRIVATE_KEY"));
    address admin = vm.envAddress("CLAIM_TOKEN_ADMIN_ADDRESS");
    address signer = vm.envAddress("CLAIM_TOKEN_SIGNER_ADDRESS");

    function run() external {
        address[] memory signers = new address[](1);
        signers[0] = signer;

        vm.startBroadcast(deployer);
        claimToken = new ClaimToken(admin, signers);
        vm.stopBroadcast();

        string memory currentNetwork = Network.getNetworkName(block.chainid);
        string memory outputFilePath = "script/output/Address.json";
        string memory jsonData =
            string.concat('{"', currentNetwork, '":{"claimToken":"', vm.toString(address(claimToken)), '"}}');
        vm.writeJson(jsonData, outputFilePath);

        console.log("claimToken:");
        console.logAddress(address(claimToken));
    }
}
