# Ether Wallet

## Overview

Ether Wallet is a smart contract implemented on the Ethereum blockchain that allows users to securely deposit and withdraw Ether. The contract includes features such as fund tracking, withdrawal by the contract owner, and the ability to pause and unpause contract operations. The contract is tested using the Foundry framework, ensuring robust functionality and security.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Installation](#installation)
  - [Deployment](#deployment)
- [Contract Details](#contract-details)
  - [Functions](#functions)
  - [Events](#events)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Fund Functionality:** Users can fund the wallet by sending Ether to the contract. The minimum required amount is enforced to ensure meaningful transactions.
- **Withdrawal Functionality:** Only the contract owner can withdraw all the Ether from the contract. After withdrawal, the contract resets the funders' array and mapping.
- **Pause and Unpause:** The owner can pause and unpause the contract, preventing any funding while the contract is paused.
- **Fallback and Receive Functions:** The contract can accept Ether via both direct transfers and calls with data, ensuring flexibility in how funds are sent.
- **Ownership Control:** Only the owner has control over critical functions like withdrawal and pausing/unpausing the contract.

## Prerequisites

- [Node.js](https://nodejs.org/en/)
- [Foundry](https://book.getfoundry.sh/)
- [Hardhat](https://hardhat.org/) (Optional)
- An Ethereum wallet like [MetaMask](https://metamask.io/)
- A local Ethereum node or a service like [Infura](https://infura.io/)

## Getting Started

### Installation

1. **Clone the Repository**
    ```bash
    git clone https://github.com/yourusername/ether-wallet.git
    cd ether-wallet
    ```

2. **Install Dependencies**
    ```bash
    forge install
    ```

3. **Set Up Foundry**
    Install Foundry if you haven't already:
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

### Deployment

1. **Deploy Locally**

   You can deploy the contract locally using foundry, `defaultKey` is the local private key(Anvil) stored in keyStore :

    ```bash
    forge script <-scriptName-> --rpc-url https://127.0.0.1:8545 --account defaultKey --sender <-senderAddress-> --broadcast
    ```

2. **Deploy on Testnet/Mainnet**

   Update your `.env` file and keyStore with the necessary API keys and wallet details, then deploy:

    ```bash
    forge script <-scriptName-> --rpc-url $RPC_URL --account defaultKey --sender <-senderAddress-> --broadcast
    ```

## Contract Details

### Functions

- **fund()**: Allows users to fund the contract with a minimum amount of Ether.
- **withdraw()**: Allows the owner to withdraw all Ether from the contract.
- **pause()**: Pauses the contract, preventing new funds from being added.
- **unpause()**: Unpauses the contract, allowing funds to be added again.
- **getOwner()**: Returns the owner of the contract.
- **getPauseStatus()**: Returns whether the contract is paused.
- **getBalance()**: Returns the current balance of the contract.
- **getVersion()**: Returns the version of the price feed.
- **getFunderToFundAmount(address)**: Returns the amount funded by a specific address.
- **getFunder(uint256)**: Returns the address of the funder at the specified index.
- **getFunderArrayLength()**: Returns the number of unique funders.
- **gethasFunded(address)**: Returns whether a specific address has funded the contract.

### Events

- **Funded(address indexed funder, uint256 amount)**: Emitted when a user funds the contract.
- **Withdrawn(address indexed owner, uint256 amount)**: Emitted when the owner withdraws funds.

## Testing

The contract is tested using the Foundry framework. Tests are written to cover all core functionalities, including funding, withdrawal, pausing, and ownership checks.

### Running Tests

To run the tests, execute:

```bash
forge test
```

This will run all the test cases defined in the TestEtherWallet contract, ensuring that the contract behaves as expected under various conditions.

## Contributing

Contributions are welcome! To contribute:

- Fork the repository.
- Create a new branch (git checkout -b feature-branch).
- Commit your changes (git commit -am 'Add new feature').
- Push to the branch (git push origin feature-branch).
- Open a Pull Request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
