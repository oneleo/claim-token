// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {ECDSA} from "@oz/utils/cryptography/ECDSA.sol";
import {Ownable} from "@oz/access/Ownable.sol";
import {ERC20} from "@oz/token/ERC20/ERC20.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@oz/interfaces/draft-IERC6093.sol";
import {MessageHashUtils} from "@oz/utils/cryptography/MessageHashUtils.sol";

import {ClaimToken} from "src/ClaimToken.sol";
import {IClaimToken} from "src/interfaces/IClaimToken.sol";

contract MockTokenMintable is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract ClaimTokenTest is Test {
    using ECDSA for bytes32;

    ClaimToken private claimToken;

    address admin;
    uint256 adminKey;
    address signer;
    uint256 signerKey;
    address other;
    uint256 otherKey;
    address user;

    string[] eventName = new string[](3);
    MockTokenMintable[] eventToken = new MockTokenMintable[](2);

    function setUp() public {
        (admin, adminKey) = makeAddrAndKey("admin");
        (signer, signerKey) = makeAddrAndKey("signer");
        (other, otherKey) = makeAddrAndKey("other");
        user = makeAddr("user");

        address[] memory signers = new address[](1);
        signers[0] = signer;
        claimToken = new ClaimToken(admin, signers);

        vm.deal(address(this), 1000 ether);

        eventName[0] = "eventName[0]";
        eventName[1] = "eventName[1]";
        eventName[2] = "eventName[2]";
        eventToken[0] = new MockTokenMintable("EventToken[0]", "ET0");
        eventToken[1] = new MockTokenMintable("EventToken[1]", "ET1");
    }

    function testSetUp() public view {
        console.logAddress(address(claimToken));
        assertEq(claimToken.owner(), admin);
        assertEq(claimToken.isSignerActivated(signer), true);
        assertEq(claimToken.getSigners()[0], signer);
    }

    function testUpdateSignerByAdmin() public {
        address[] memory signers = new address[](2);
        signers[0] = makeAddr("signers[0]");
        signers[1] = makeAddr("signers[1]");

        bool[] memory isActivated = new bool[](2);
        isActivated[0] = true;
        isActivated[1] = false;

        vm.expectEmit(true, true, false, false, address(claimToken));
        emit IClaimToken.SignerUpdated(signers[0], true);

        vm.expectEmit(true, true, false, false, address(claimToken));
        emit IClaimToken.SignerUpdated(signers[1], false);

        vm.startPrank(admin);
        claimToken.updateSigners(signers, isActivated);
        vm.stopPrank();

        assertEq(claimToken.isSignerActivated(signers[0]), true);
        assertEq(claimToken.isSignerActivated(signers[1]), false);

        assertEq(claimToken.getSigners().length, 2);
        assertEq(claimToken.getSigners()[1], signers[0]);
    }

    function testCannotUpdateSignerByOther() public {
        address[] memory signers = new address[](1);
        signers[0] = makeAddr("signers[0]");

        bool[] memory isActivated = new bool[](1);
        isActivated[0] = false;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(other)));

        vm.startPrank(other);
        claimToken.updateSigners(signers, isActivated);
        vm.stopPrank();
    }

    function testCreateEventByAdmin() public {
        string memory eventID = eventName[0];
        address tokenAddress = address(eventToken[0]);

        vm.expectEmit(true, true, false, false, address(claimToken));
        emit IClaimToken.EventCreated(tokenAddress, eventID);

        // Create event by admin
        vm.startPrank(admin);
        claimToken.createNewEvent(tokenAddress, eventID);
        vm.stopPrank();

        assertEq(claimToken.getEvent(tokenAddress, eventID), false);
    }

    function testCreateEventByNewAdmin() public {
        address newAdmin = makeAddr("newAdmin");

        vm.startPrank(admin);
        claimToken.transferOwnership(newAdmin);
        vm.stopPrank();

        string memory eventID = eventName[0];
        address tokenAddress = address(eventToken[0]);

        vm.expectEmit(true, true, false, false, address(claimToken));
        emit IClaimToken.EventCreated(tokenAddress, eventID);

        // Create event by newAdmin
        vm.startPrank(newAdmin);
        claimToken.createNewEvent(tokenAddress, eventID);
        vm.stopPrank();

        assertEq(claimToken.getEvent(tokenAddress, eventID), false);
    }

    function testCannotCreateEventByOther() public {
        string memory eventID = eventName[0];
        address tokenAddress = address(eventToken[0]);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(other)));

        // Create event by other
        vm.startPrank(other);
        claimToken.createNewEvent(tokenAddress, eventID);
        vm.stopPrank();
    }

    // TODO: testCannotCreateEventByOldAdmin

    function testUpdateEvent() public {
        string memory eventID = eventName[0];
        address tokenAddress = address(eventToken[0]);

        // Create event by admin
        vm.startPrank(admin);
        claimToken.createNewEvent(tokenAddress, eventID);
        vm.stopPrank();

        // Update event to close by admin
        vm.startPrank(admin);
        claimToken.updateEvent(tokenAddress, eventID, true);
        vm.stopPrank();

        assertEq(claimToken.getEvent(tokenAddress, eventID), true);
    }

    // TODO: testCannotUpdateEventByOther
    // TODO: testCannotUpdateEventByOldAdmin

    function testCannotUpdateEventToSameState() public {
        string memory eventID = eventName[0];
        address tokenAddress = address(eventToken[0]);

        // Create event by admin
        vm.startPrank(admin);
        claimToken.createNewEvent(tokenAddress, eventID);
        vm.stopPrank();

        vm.expectRevert("Event already in this state");

        // Update event to open by admin
        vm.startPrank(admin);
        claimToken.updateEvent(tokenAddress, eventID, false);
        vm.stopPrank();
    }

    function testClaimUsingSignerKey() public {
        address tokenAddress = address(eventToken[0]);
        string memory eventID = eventName[0];
        uint256 amount = 100 ether;

        // Create Event by admin
        vm.startPrank(admin);
        claimToken.createNewEvent(tokenAddress, eventID);
        vm.stopPrank();

        // Mint token to claimToken for event
        eventToken[0].mint(address(claimToken), 1000 ether);

        bytes32 eventIDHash = keccak256(abi.encodePacked(eventID));
        bytes32 claimHash = keccak256(abi.encode(tokenAddress, eventIDHash, user, amount));
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(claimHash);

        // Sign signature by signer
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, true, true, address(claimToken));
        emit IClaimToken.Claimed(claimHash, tokenAddress, eventID, user, amount, signature);

        uint256 tokenBalanceBefore = eventToken[0].balanceOf(user);

        // Claim token to user by other
        vm.startPrank(other);
        claimToken.claim(tokenAddress, eventID, user, amount, signature);
        vm.stopPrank();

        uint256 tokenBalanceAfter = eventToken[0].balanceOf(user);

        assertEq(claimToken.getClaimStatus(tokenAddress, eventID, user), tokenBalanceAfter - tokenBalanceBefore);
    }

    function testClaimUsingNewSignerKey() public {
        address newSigner;
        uint256 newSignerKey;
        address[] memory signers = new address[](1);
        bool[] memory isActivated = new bool[](1);

        // To fix the "Stack too deep" issue
        {
            (newSigner, newSignerKey) = makeAddrAndKey("newSigner");
            signers[0] = newSigner;
            isActivated[0] = true;
        }

        // Add signer by admin
        vm.startPrank(admin);
        claimToken.updateSigners(signers, isActivated);
        vm.stopPrank();

        address tokenAddress = address(eventToken[0]);
        string memory eventID = eventName[0];
        uint256 amount = 100 ether;

        // Create Event by admin
        vm.startPrank(admin);
        claimToken.createNewEvent(tokenAddress, eventID);
        vm.stopPrank();

        // Mint token to claimToken for event
        eventToken[0].mint(address(claimToken), 1000 ether);

        bytes32 claimHash;
        bytes memory signature;

        // To fix the "Stack too deep" issue
        {
            bytes32 eventIDHash = keccak256(abi.encodePacked(eventID));
            claimHash = keccak256(abi.encode(tokenAddress, eventIDHash, user, amount));
            bytes32 ethSignedMessageHash = _getEthSignedMessageHash(claimHash);

            // Sign signature by signer
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(newSignerKey, ethSignedMessageHash);
            signature = abi.encodePacked(r, s, v);
        }

        vm.expectEmit(true, true, true, true, address(claimToken));
        emit IClaimToken.Claimed(claimHash, tokenAddress, eventID, user, amount, signature);

        uint256 tokenBalanceBefore = eventToken[0].balanceOf(user);

        // Claim token to user by other
        vm.startPrank(other);
        claimToken.claim(tokenAddress, eventID, user, amount, signature);
        vm.stopPrank();

        uint256 tokenBalanceAfter = eventToken[0].balanceOf(user);

        assertEq(claimToken.getClaimStatus(tokenAddress, eventID, user), tokenBalanceAfter - tokenBalanceBefore);
    }

    function testCannotClaimUsingOtherKey() public {
        address tokenAddress = address(eventToken[0]);
        string memory eventID = eventName[0];
        uint256 amount = 100 ether;

        // Create Event by admin
        vm.startPrank(admin);
        claimToken.createNewEvent(tokenAddress, eventID);
        vm.stopPrank();

        // Mint token to claimToken for event
        eventToken[0].mint(address(claimToken), 1000 ether);

        bytes32 eventIDHash = keccak256(abi.encodePacked(eventID));
        bytes32 claimHash = keccak256(abi.encode(tokenAddress, eventIDHash, user, amount));
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(claimHash);

        // Sign signature by other
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(otherKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Invalid signer");

        // Claim token to user by other
        vm.startPrank(other);
        claimToken.claim(tokenAddress, eventID, user, amount, signature);
        vm.stopPrank();
    }

    // TODO: testCannotClaimUsingOldSignerKey

    function testCannotClaimIfEventIsClosed() public {
        address tokenAddress = address(eventToken[0]);
        string memory eventID = eventName[0];
        uint256 amount = 100 ether;

        // Create Event by admin
        vm.startPrank(admin);
        claimToken.createNewEvent(tokenAddress, eventID);
        vm.stopPrank();

        // Update event to close by admin
        vm.startPrank(admin);
        claimToken.updateEvent(tokenAddress, eventID, true);
        vm.stopPrank();

        // Mint token to claimToken for event
        eventToken[0].mint(address(claimToken), 1000 ether);

        bytes32 eventIDHash = keccak256(abi.encodePacked(eventID));
        bytes32 claimHash = keccak256(abi.encode(tokenAddress, eventIDHash, user, amount));
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(claimHash);

        // Sign signature by signer
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Event is closed");

        // Claim token to user by other
        vm.startPrank(other);
        claimToken.claim(tokenAddress, eventID, user, amount, signature);
        vm.stopPrank();
    }

    function testCannotClaimWithInsufficientBalance() public {
        address tokenAddress = address(eventToken[0]);
        string memory eventID = eventName[0];
        uint256 amount = 100 ether;

        // Create Event by admin
        vm.startPrank(admin);
        claimToken.createNewEvent(tokenAddress, eventID);
        vm.stopPrank();

        // Mint token to claimToken for event
        eventToken[0].mint(address(claimToken), 10 ether);

        bytes32 eventIDHash = keccak256(abi.encodePacked(eventID));
        bytes32 claimHash = keccak256(abi.encode(tokenAddress, eventIDHash, user, amount));
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(claimHash);

        // Sign signature by signer
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Insufficient balance");

        // Claim token to user by other
        vm.startPrank(other);
        claimToken.claim(tokenAddress, eventID, user, amount, signature);
        vm.stopPrank();
    }

    function testCannotClaimToZeroAddress() public {
        address zeroAddress = address(0);

        address tokenAddress = address(eventToken[0]);
        string memory eventID = eventName[0];
        uint256 amount = 100 ether;

        // Create Event by admin
        vm.startPrank(admin);
        claimToken.createNewEvent(tokenAddress, eventID);
        vm.stopPrank();

        // Mint token to claimToken for event
        eventToken[0].mint(address(claimToken), 1000 ether);

        bytes32 eventIDHash = keccak256(abi.encodePacked(eventID));
        bytes32 claimHash = keccak256(abi.encode(tokenAddress, eventIDHash, zeroAddress, amount));
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(claimHash);

        // Sign signature by signer
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(zeroAddress)));

        // Claim token to zeroAddress by other
        vm.startPrank(other);
        claimToken.claim(tokenAddress, eventID, zeroAddress, amount, signature);
        vm.stopPrank();
    }

    function testCannotReceiveETH() public {
        vm.expectRevert("ETH transfers are not accepted");

        payable(claimToken).transfer(1 ether);
    }

    function testCannotCallNonExistentFunction() public {
        (bool success,) = address(claimToken).call(abi.encodeWithSignature("nonExistentFunction()"));

        assertEq(success, false);
    }

    function testCannotCallNonExistentFunctionWithETH() public {
        (bool success,) = address(claimToken).call{value: 1 ether}(abi.encodeWithSignature("nonExistentFunction()"));

        assertEq(success, false);
    }

    // -------------------
    // -- Util function --
    // -------------------

    function _getEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return MessageHashUtils.toEthSignedMessageHash(keccak256(abi.encode(hash)));
    }
}
