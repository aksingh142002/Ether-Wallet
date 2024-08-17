# Ether Wallet Contract

This is a simple Ether wallet smart contract built on the Ethereum blockchain. The contract allows users to fund it with Ether and allows the owner to withdraw the accumulated funds. Additionally, it has pause and unpause functionality to prevent or allow certain operations as needed.

## Features

- **Funding**: Anyone can fund the contract with Ether, provided they meet the minimum required amount in USD.
- **Withdrawal**: Only the contract owner can withdraw all the funds from the contract.
- **Pause/Unpause**: The contract owner can pause or unpause the contract, restricting or allowing certain operations.
- **Event Logging**: Logs important actions like funding and withdrawal.

## Contract Details

- **Minimum Funding Amount**: The contract requires a minimum funding amount of 5 USD worth of Ether.
- **Owner Only Operations**: Only the owner can pause, unpause, and withdraw funds from the contract.

## Functions

### 1. `fund()`
Allows users to send Ether to the contract. The sent amount must meet the minimum USD value required.

### 2. `withdraw()`
Allows the contract owner to withdraw all the Ether from the contract. This function also resets the balance of each funder.

### 3. `pause()`
Pauses the contract, preventing users from funding it. Can only be called by the owner.

### 4. `unpause()`
Unpauses the contract, allowing users to fund it again. Can only be called by the owner.

### 5. `getBalance()`
Returns the current balance of the contract in Ether.

### 6. `receive()`
Handles direct Ether transfers to the contract and calls the `fund()` function.

### 7. `fallback()`
Handles calls to the contract that do not match any other function signatures and directs them to `fund()`.

## Events

- **Funded**: Emitted when someone funds the contract.
- **Withdrawn**: Emitted when the owner withdraws funds from the contract.

## Usage

1. **Deploy the Contract**: Deploy the contract on an Ethereum-compatible network.
2. **Fund the Contract**: Users can send Ether to the contract using the `fund()` function.
3. **Pause/Unpause the Contract**: The owner can pause or unpause the contract using the respective functions.
4. **Withdraw Funds**: The owner can withdraw all funds from the contract using the `withdraw()` function.

## Security Features

- **Ownership**: Only the owner can execute critical functions like `withdraw()`, `pause()`, and `unpause()`.
- **Circuit Breaker**: The contract includes pause and unpause functionality to quickly respond to unexpected behavior.
- **Reentrancy Protection**: State changes are made before external calls to mitigate reentrancy attacks.

## License

This project is licensed under the MIT License.
