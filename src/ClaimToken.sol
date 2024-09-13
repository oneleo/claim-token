// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {ECDSA} from "@oz/utils/cryptography/ECDSA.sol";
import {Ownable} from "@oz/access/Ownable.sol";
import {MessageHashUtils} from "@oz/utils/cryptography/MessageHashUtils.sol";

import {IClaimToken} from "src/interfaces/IClaimToken.sol";

contract ClaimToken is IClaimToken, Ownable {
    using ECDSA for bytes32;

    // -----------------------
    // -- Private Variables --
    // -----------------------

    // signer => activated
    mapping(address => bool) private _isActivatedSigner;

    // List of signers
    address[] private _signerList;

    // token => event => user => amount
    mapping(address => mapping(bytes32 => mapping(address => uint256))) private _userClaimedAmount;

    // token => event => opened
    mapping(address => mapping(bytes32 => bool)) private _isEventOngoing;

    // token => event
    mapping(address => bytes32[]) private _tokenEventList;

    // token => totalAmount
    mapping(address => uint256) private _totalClaimedAmount;

    // List of event IDs
    bytes32[] private _eventList;

    // Reentrancy guard
    bool private _locked;

    // ---------------
    // -- Modifiers --
    // ---------------

    // Prevents reentrancy attacks
    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    // Ensures function is called by an active signer
    modifier onlyActivatedSigner() {
        require(_isActivatedSigner[msg.sender], "Not an active signer");
        _;
    }

    // -----------------
    // -- Constructor --
    // -----------------

    constructor(address _admin) Ownable(_admin) {
        _isActivatedSigner[_admin] = true;
        _addSigner(_admin);
    }

    // -------------------
    // -- Get Functions --
    // -------------------

    // Checks if a signer is activated
    function isSignerActivated(address _signer) external view override returns (bool isActivated) {
        return _isActivatedSigner[_signer];
    }

    // Checks if a signer exists
    function isSignerExists(address _signer) public view returns (bool) {
        for (uint256 i = 0; i < _signerList.length; i++) {
            if (_signerList[i] == _signer) {
                return true;
            }
        }
        return false;
    }

    // Checks if an event ID exists
    function isEventExists(bytes32 _eventIDHash) public view returns (bool) {
        for (uint256 i = 0; i < _eventList.length; i++) {
            if (_eventList[i] == _eventIDHash) {
                return true;
            }
        }
        return false;
    }

    // Checks if a token has an associated event
    function isTokenEventExists(address _tokenAddress, bytes32 _eventIDHash) public view returns (bool) {
        for (uint256 i = 0; i < _tokenEventList[_tokenAddress].length; i++) {
            if (_tokenEventList[_tokenAddress][i] == _eventIDHash) {
                return true;
            }
        }
        return false;
    }

    // Gets the closure status of an event
    function getEvent(address tokenAddress, string calldata eventID)
        external
        view
        override
        returns (bool isEventClosed)
    {
        bytes32 eventIDHash = keccak256(abi.encodePacked(eventID));
        return !_isEventOngoing[tokenAddress][eventIDHash];
    }

    // Gets the list of all events
    function getEvents() external view returns (bytes32[] memory) {
        return _eventList;
    }

    // Gets the claimed amount for a user in a specific event
    function getClaimStatus(address tokenAddress, string calldata eventID, address userAddress)
        external
        view
        override
        returns (uint256 claimedAmount)
    {
        bytes32 eventIDHash = keccak256(abi.encodePacked(eventID));
        return _userClaimedAmount[tokenAddress][eventIDHash][userAddress];
    }

    // Gets the contract's token balance for a specified token
    function getTokenBalance(address _tokenAddress) public view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    // Gets the list of all signers
    function getSigners() external view returns (address[] memory) {
        return _signerList;
    }

    // -------------------
    // -- Set Functions --
    // -------------------

    // Updates signers and their activation status
    function updateSigners(address[] memory signerList, bool[] memory isActivatedList) external override onlyOwner {
        require(signerList.length == isActivatedList.length, "Mismatch in input lengths");

        for (uint256 i = 0; i < signerList.length; i++) {
            address signer = signerList[i];
            bool isActivatedSigner = isActivatedList[i];
            _isActivatedSigner[signer] = isActivatedSigner;

            if (isActivatedSigner) {
                _addSigner(signer);
            } else {
                require(signer != owner(), "Contract owner cannot be removed");
                _removeSigner(signer);
            }

            emit SignerUpdated(signer, isActivatedSigner);
        }
    }

    // Creates a new event with the specified ID and token address
    function createNewEvent(address tokenAddress, string calldata eventID) external override onlyActivatedSigner {
        bytes32 eventIDHash = keccak256(abi.encodePacked(eventID));
        _addEventID(eventIDHash);
        _isEventOngoing[tokenAddress][eventIDHash] = true;
        _addTokenEvent(tokenAddress, eventIDHash);
        emit EventCreated(tokenAddress, eventID);
    }

    // Updates the status of an existing event
    function updateEvent(address tokenAddress, string calldata eventID, bool isEventClosed)
        external
        override
        onlyActivatedSigner
    {
        bytes32 eventIDHash = keccak256(abi.encodePacked(eventID));

        require(isTokenEventExists(tokenAddress, eventIDHash), "Event ID does not exist");

        require(_isEventOngoing[tokenAddress][eventIDHash] != !isEventClosed, "Event already in this state");

        _isEventOngoing[tokenAddress][eventIDHash] = !isEventClosed;
        emit EventUpdated(tokenAddress, eventID, isEventClosed);
    }

    // Claims tokens for a user based on the provided data
    function claim(
        address tokenAddress,
        string calldata eventID,
        address userAddress,
        uint256 amount,
        bytes calldata signerSignature
    ) external override onlyActivatedSigner nonReentrant {
        bytes32 eventIDHash = keccak256(abi.encodePacked(eventID));
        require(_isEventOngoing[tokenAddress][eventIDHash], "Event is closed");

        require(getTokenBalance(tokenAddress) >= amount, "Insufficient balance");

        bytes32 claimHash = keccak256(abi.encode(tokenAddress, eventIDHash, userAddress, amount));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(keccak256(abi.encode(claimHash)));
        address signer = ECDSA.recover(ethSignedMessageHash, signerSignature);

        require(_isActivatedSigner[signer], "Invalid signer");

        require(IERC20(tokenAddress).transfer(userAddress, amount), "Token transfer failed");

        _userClaimedAmount[tokenAddress][eventIDHash][userAddress] += amount;
        _totalClaimedAmount[tokenAddress] += amount;

        emit Claimed(claimHash, tokenAddress, eventID, userAddress, amount, signerSignature);
    }

    // Transfers tokens from the contract to a recipient
    function transferToken(address tokenAddress, address recipient, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
        require(getTokenBalance(tokenAddress) >= amount, "Insufficient balance");

        IERC20(tokenAddress).transfer(recipient, amount);
    }

    // ------------------------
    // -- internal Functions --
    // ------------------------

    // Adds a new signer to the list
    function _addSigner(address _signer) internal {
        if (isSignerExists(_signer)) {
            return;
        }
        _signerList.push(_signer);
    }

    // Removes a signer from the list
    function _removeSigner(address _signer) internal {
        if (!isSignerExists(_signer)) {
            return;
        }
        // Find the index of the signer to be removed
        for (uint256 i = 0; i < _signerList.length; i++) {
            if (_signerList[i] == _signer) {
                // Swap the signer with the last element and remove the last element
                _signerList[i] = _signerList[_signerList.length - 1];
                _signerList.pop();
                break;
            }
        }
    }

    // Adds a new event to the list for a token
    function _addTokenEvent(address _tokenAddress, bytes32 _eventIDHash) internal {
        require(!isTokenEventExists(_tokenAddress, _eventIDHash), "Event ID already associated with token");

        _tokenEventList[_tokenAddress].push(_eventIDHash);
    }

    // Adds a new event ID to the event list
    function _addEventID(bytes32 eventIDHash) internal {
        if (isEventExists(eventIDHash)) {
            return;
        }
        _eventList.push(eventIDHash);
    }

    // ------------------------
    // -- Reserved functions --
    // ------------------------

    // Rejects ETH transfers to the contract
    receive() external payable {
        revert("ETH transfers are not accepted");
    }

    // Rejects unexpected function calls and ETH transfers
    fallback() external payable {
        revert("Unexpected call or ETH transfer is not accepted");
    }
}
