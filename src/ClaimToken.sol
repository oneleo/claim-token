// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "@oz/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@oz/utils/cryptography/ECDSA.sol";
import {Ownable2Step, Ownable} from "@oz/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@oz/utils/ReentrancyGuard.sol";
import {EnumerableSet} from "@oz/utils/structs/EnumerableSet.sol";
import {MessageHashUtils} from "@oz/utils/cryptography/MessageHashUtils.sol";

import {IClaimToken} from "src/interfaces/IClaimToken.sol";

contract ClaimToken is IClaimToken, Ownable2Step, ReentrancyGuard {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    // -----------------------
    // -- Private Variables --
    // -----------------------

    mapping(address signer => bool isActivated) private _isActivatedSigner;
    mapping(address token => mapping(bytes32 eventIDHash => mapping(address user => uint256 amount))) private
        _userClaimedAmount;
    mapping(address token => mapping(bytes32 eventIDHash => bool isEventOngoing)) private _isEventOngoing;
    mapping(address token => mapping(bytes32 eventIDHash => bool isEventCreated)) private _isEventCreated;

    // List of signers
    EnumerableSet.AddressSet private _signerSet;

    // -----------------
    // -- Constructor --
    // -----------------

    constructor(address _admin, address[] memory signers) Ownable(_admin) {
        bool[] memory isActivatedList = new bool[](signers.length);
        for (uint256 i = 0; i < signers.length; i++) {
            isActivatedList[i] = true;
        }

        _updateSigners(signers, isActivatedList);
    }

    // -------------------
    // -- Get Functions --
    // -------------------

    // Checks if a signer is activated
    function isSignerActivated(address _signer) external view override returns (bool isActivated) {
        return _isActivatedSigner[_signer];
    }

    // Gets the closure status of an event
    function getEvent(address tokenAddress, string calldata eventID)
        external
        view
        override
        returns (bool isEventClosed)
    {
        bytes32 eventIDHash = _hashString(eventID);
        return !_isEventOngoing[tokenAddress][eventIDHash];
    }

    // Gets the claimed amount for a user in a specific event
    function getClaimStatus(address tokenAddress, string calldata eventID, address userAddress)
        external
        view
        override
        returns (uint256 claimedAmount)
    {
        bytes32 eventIDHash = _hashString(eventID);
        return _userClaimedAmount[tokenAddress][eventIDHash][userAddress];
    }

    // Gets the list of all signers
    function getSigners() external view returns (address[] memory) {
        return _signerSet.values();
    }

    function getClaimHash(address tokenAddress, string calldata eventID, address userAddress, uint256 amount)
        public
        pure
        returns (bytes32)
    {
        bytes32 eventIDHash = _hashString(eventID);
        return keccak256(abi.encode(tokenAddress, eventIDHash, userAddress, amount));
    }

    // -------------------
    // -- Set Functions --
    // -------------------

    // Updates signers and their activation status
    function updateSigners(address[] memory signerList, bool[] memory isActivatedList) external override onlyOwner {
        _updateSigners(signerList, isActivatedList);
    }

    // Creates a new event with the specified ID and token address
    function createNewEvent(address tokenAddress, string calldata eventID, bool startEvent)
        external
        override
        onlyOwner
    {
        bytes32 eventIDHash = _hashString(eventID);

        require(!_isEventCreated[tokenAddress][eventIDHash], EventIdTokenAlreadyCreated());

        _isEventOngoing[tokenAddress][eventIDHash] = startEvent;
        _isEventCreated[tokenAddress][eventIDHash] = true;
        emit EventCreated(tokenAddress, eventID);
    }

    // Updates the status of an existing event
    function updateEvent(address tokenAddress, string calldata eventID, bool isEventClosed)
        external
        override
        onlyOwner
    {
        bytes32 eventIDHash = _hashString(eventID);

        require(_isEventCreated[tokenAddress][eventIDHash], EventIdTokenNotCreated());

        require(_isEventOngoing[tokenAddress][eventIDHash] != !isEventClosed, EventAlreadyInState());

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
    ) external override nonReentrant {
        bytes32 eventIDHash = _hashString(eventID);
        require(_isEventOngoing[tokenAddress][eventIDHash], EventClosed());

        require(_userClaimedAmount[tokenAddress][eventIDHash][userAddress] == 0, UserAlreadyClaimedToken(userAddress));

        bytes32 claimHash = getClaimHash(tokenAddress, eventID, userAddress, amount);
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(claimHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signerSignature);

        require(_isActivatedSigner[signer], InvalidSignerAddress(signer));

        SafeERC20.safeTransfer(IERC20(tokenAddress), userAddress, amount);

        _userClaimedAmount[tokenAddress][eventIDHash][userAddress] += amount;

        emit Claimed(claimHash, tokenAddress, eventID, userAddress, amount, signerSignature);
    }

    // ------------------------
    // -- Internal Functions --
    // ------------------------

    function _hashString(string memory input) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(input));
    }

    // -----------------------
    // -- Private Functions --
    // -----------------------

    // Updates signers and their activation status
    function _updateSigners(address[] memory _signerList, bool[] memory _isActivatedList) private {
        require(_signerList.length == _isActivatedList.length, MismatchInInputLengths());

        for (uint256 i = 0; i < _signerList.length; i++) {
            address signer = _signerList[i];

            require(signer != address(0), InvalidSignerAddress(signer));

            bool isActivatedSigner = _isActivatedList[i];

            if (isActivatedSigner == _isActivatedSigner[signer]) {
                if (isActivatedSigner) {
                    revert SignerAlreadyActive(signer);
                } else {
                    revert SignerAlreadyDeactivated(signer);
                }
            }

            if (isActivatedSigner) {
                _signerSet.add(signer);
            } else {
                _signerSet.remove(signer);
            }

            _isActivatedSigner[signer] = isActivatedSigner;

            emit SignerUpdated(signer, isActivatedSigner);
        }
    }
}
