## ClaimToken Contract

The `ClaimToken` contract facilitates secure and efficient token distribution for events. It allows administrators to manage token-based events and signers, while ensuring users can claim their allocated tokens once, using a valid signature from authorized signers.

### Key Features:

- **Event Management**: Administrators can create, update, and close token events.
- **Claim Process**: Users claim tokens via a valid signature from activated signers.
- **Signer Management**: Administrators manage the list of authorized signers.

### Events:

- **SignerUpdated**: Triggered when a signer's status changes.
- **EventCreated**: Triggered when a token event is created.
- **EventUpdated**: Triggered when an event's status is updated.
- **Claimed**: Triggered when a user claims tokens.

### Functions:

- **Query Functions**:

  - `isSignerActivated`: Check signer status.
  - `getEvent`: Retrieve event status.
  - `getClaimStatus`: Check a user's claim status.

- **Administrative Functions**:
  - `updateSigners`: Manage signer list and statuses.
  - `createNewEvent`: Initiate a token event.
  - `updateEvent`: Modify event status.
  - `claim`: Users claim tokens using a valid signature.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Deploy and verify

- Copy and modify the deployment variables with `cp .env.example .env`, then run the following command.
- The claimToken contract address will be saved in `script/Address.json`.

```shell
$ chmod +x script/DeployClaimToken.sh
$ script/DeployClaimToken.sh
```

## Setup & Update

Here are the setup and update processes:

1. **Setup Diagram**:  
   ![Setup Diagram](assets/setupDiagram.png)

2. **Update Diagram**:  
   ![Update Diagram](assets/updateDiagram.png)

## Claim Process Flow

Visual representation of the claim process:

1. **Eligibility Check**:  
   ![Claim Check](assets/claimCheck.png)

2. **Admin Signs Claim**:

   - Admin signs with `[token address, event id, user address, amount]`  
     ![Admin Signs](assets/adminSigns.png)

3. **Relayer Submission**:  
   ![Relayer Submission](assets/relayerSubmission.png)

4. **Transaction Success**:

   - Indexer notifies backend after execution, updating claim status.  
     ![Transaction Success](assets/transactionSuccess.png)

5. **Delayed Transactions**:
   - User reclaims if no execution.  
     ![User Reclaims](assets/userReclaims.png)
   - Relayer retries if no execution in 3 minutes.  
     ![Relayer Retries](assets/relayerRetries.png)
