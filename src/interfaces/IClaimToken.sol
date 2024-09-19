// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";

interface IClaimToken {
    // ------------
    // -- Events --
    // ------------

    // Event for signer updates
    event SignerUpdated(address indexed signer, bool indexed isActivated);

    // Event for event creation
    event EventCreated(address indexed tokenAddress, string indexed eventID);

    // Event for event status updates
    event EventUpdated(address indexed tokenAddress, string indexed eventID, bool indexed isEventClosed);

    // Event for claiming tokens
    event Claimed(
        bytes32 claimHash,
        address indexed tokenAddress,
        string eventID,
        address indexed userAddress,
        uint256 indexed amount,
        bytes signerSignature
    );

    // ------------
    // -- Errors --
    // ------------

    error InvalidSignerAddress(address signer);

    error SignerAlreadyActive(address signer);

    error SignerAlreadyDeactivated(address signer);

    error UserAlreadyClaimedToken(address user);

    error EventIdTokenAlreadyCreated();

    error EventIdTokenNotCreated();

    error EventAlreadyInState();

    error EventClosed();

    error MismatchInInputLengths();

    // -------------------
    // -- Get Functions --
    // -------------------

    // Function to check if a signer is activated
    function isSignerActivated(address signer) external view returns (bool isActivated);

    // Function to retrieve event status
    function getEvent(address tokenAddress, string calldata eventID) external view returns (bool isEventClosed);

    // Function to check user claim status
    function getClaimStatus(address tokenAddress, string calldata eventID, address userAddress)
        external
        view
        returns (uint256 claimedAmount);

    // -------------------
    // -- Set Functions --
    // -------------------

    // Function to update list of signers
    function updateSigners(address[] calldata signerList, bool[] calldata isActivatedList) external;

    // Function to create a new event
    function createNewEvent(address tokenAddress, string calldata eventID, bool startEvent) external;

    // Function to update event status (active or closed)
    function updateEvent(address tokenAddress, string calldata eventID, bool isEventClosed) external;

    // Function to claim tokens
    function claim(
        address tokenAddress,
        string calldata eventID,
        address userAddress,
        uint256 amount,
        bytes calldata signerSignature
    ) external;
}
