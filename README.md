Subscription Management Smart Contract
This project is a smart contract for managing subscriptions on the Stacks blockchain. It allows content creators to register themselves, set subscription fees, and manage their content. Users can subscribe to creators and manage their subscriptions securely and transparently.


Features
Register Content Creators: Creators can register themselves with a unique content hash and a subscription fee.

Update Content: Creators can update their content hash after registration.

Manage Subscriptions: Users can subscribe to or cancel subscriptions to different creators.

Check Subscription Status: Users can check their subscription status and details for any creator.

Smart Contract Constants
The smart contract defines several constants used for error handling and operations:

contract-owner: Represents the contract owner.

err-owner-only: Error returned when a non-owner tries to perform an owner-only action.

err-not-found: Error returned when a requested entity is not found.

err-already-subscribed: Error returned when a user tries to subscribe again to the same creator.

err-not-subscribed: Error returned when a user tries to cancel a subscription they do not have.

err-insufficient-balance: Error returned when a user does not have enough balance for a transaction.

err-invalid-fee: Error returned when a subscription fee is invalid (e.g., zero or negative).

err-invalid-hash: Error returned when a content hash is invalid (not 64 characters).

subscription-duration: Represents the subscription duration (30 days in seconds).

Data Structures
The smart contract uses various data structures to store information about creators and subscriptions:

Data Variables:
next-creator-id: Tracks the next unique identifier for a new creator.
next-subscription-id: Tracks the next unique identifier for a new subscription.
Maps:

creators: Stores information about each creator, including their address, subscription fee, and content hash.
subscriptions: Stores information about each subscription, including the subscriber's address, creator ID, and expiration time.

Functions
Read-Only Functions
get-creator-details (creator-id uint): Returns the details of a creator by their ID.
get-subscription-status (subscriber principal) (creator-id uint): Returns the subscription status for a subscriber and creator.
get-total-subscriptions: Returns the total number of active subscriptions.
Public Functions
register-creator (subscription-fee uint) (content-hash (string-ascii 64)):
Registers a new creator with a specified subscription fee and content hash.
Returns the new creator ID upon successful registration.
update-content (creator-id uint) (new-content-hash (string-ascii 64)):

Allows a creator to update their content hash.
Only the creator can update their content.
Returns the creator ID upon successful update.
cancel-subscription (creator-id uint):

Allows a subscriber to cancel their subscription to a creator.

Reduces the total subscription count and deletes the subscription record.
Returns ok upon successful cancellation.

Usage Examples
1. Register a Creator
To register a new creator with a subscription fee of 100 and a content hash "abcdef1234567890...":

2. Update Creator Content
To update the content hash of a creator with ID u1:

3. Cancel a Subscription
To cancel a subscription for the creator with ID u1:

Error Handling
The contract uses custom error codes for various error conditions. For example, err-owner-only is returned when a user tries to perform an action reserved for the contract owner, while err-not-found is used when a requested creator or subscription does not exist.
