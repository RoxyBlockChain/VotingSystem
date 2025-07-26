# Decentralized Voting System with Staking and Redistribution

## Overview

This project implements a comprehensive decentralized voting system on the Ethereum blockchain that incorporates economic incentives through staking, automatic redistribution of stakes based on voting outcomes, and privacy-preserving user management. The system enables:

1. Secure, transparent voting campaigns
2. Stake-based voting power
3. Automatic redistribution of stakes to winners
4. Privacy-focused user management
5. Campaign creation with custom parameters

## Key Features

### 1. Staking-Based Voting System
- **Minimum Stake Requirement**: 1 ETH/BNB to participate
- **Voting Power**: Proportional to staked amount (1 ETH = 1 Vote)
- **Stake Management**: Users can add or withdraw stakes (with restrictions)

### 2. Voting Campaign Management
- **Campaign Creation**: Specify title, options, start time, and duration
- **Time-Bound Voting**: Strict voting periods enforced by smart contracts
- **Campaign Categories**: 
  - Active (ongoing or upcoming)
  - Completed (with published results)

### 3. Economic Incentive Mechanism
- **Winner-Takes-Most**: Losing side's stakes redistributed to winning voters
- **Proportional Distribution**: Rewards based on individual stake contribution
- **Tie Handling**: No redistribution in case of tie votes

### 4. Privacy-Preserving User Management
- **Encrypted Data**: Personal information stored as hashes on-chain
- **Selective Access**: Only contract owner and user can view encrypted data
- **Secure Storage**: Original data never stored on-chain

### 5. Notification System
- **Campaign Alerts**: Automatic notifications for new campaigns
- **Acknowledgement Requirement**: Users must confirm notifications before voting
- **NFT-Style Tracking**: Digital acknowledgments stored on-chain

### 6. Comprehensive Campaign Lifecycle
1. Campaign creation by owner
2. Notification sent to all subscribers
3. Voting period (users must acknowledge notification)
4. Results publication
5. Stake redistribution
6. Reward claiming

## Smart Contract Features

### Core Functionality
- `launchCampaign()`: Create new voting campaigns
- `vote()`: Cast votes with staked ETH
- `publishResults()`: Finalize voting and determine winners
- `claimReward()`: Distribute rewards to winning voters

### User Management
- `subscribe()`: Join system with encrypted personal data
- `addStake()`: Increase voting power
- `withdrawStake()`: Partial stake withdrawal
- `updateSubscriberInfo()`: Modify encrypted information

### Security Features
- Reentrancy protection
- Time validation for voting periods
- Access control modifiers
- Input validation
- Encrypted data storage
- Stake locking during active voting

## Frontend Application

The React-based web application provides a user-friendly interface for:

- **Wallet Connection**: MetaMask integration
- **Dashboard**: Overview of stake, voting power, and active campaigns
- **Campaign Browsing**: View active and completed campaigns
- **Voting Interface**: Cast votes with adjustable voting power
- **Campaign Creation**: Launch new voting campaigns
- **Stake Management**: Add or withdraw stakes
- **Results Visualization**: Interactive charts for completed campaigns

## Workflow

### For Voters:
1. Connect wallet and subscribe with personal information
2. Stake ETH to gain voting power
3. Acknowledge campaign notifications
4. Vote during active campaign periods
5. Claim rewards after results publication

### For Campaign Creators:
1. Launch new campaign with parameters:
   - Title and description
   - Voting options
   - Start time and duration
   - Implementation standard (EIP, ERC, etc.)
   - Contact information
2. Monitor campaign status
3. Publish results after voting ends

## Technical Stack

### Smart Contracts
- **Language**: Solidity (^0.8.0)
- **Environment**: Ethereum Virtual Machine (EVM)
- **Testing**: Foundry (with comprehensive test suite)

### Frontend
- **Framework**: React.js
- **Ethereum Interaction**: ethers.js
- **UI Components**: Tailwind CSS
- **Charting**: Chart.js

## Setup and Deployment

### Prerequisites
- Node.js (v16+)
- Foundry (for contract testing)
- MetaMask wallet

### Smart Contract Deployment
1. Compile contracts: `forge build`
2. Run tests: `forge test`
3. Deploy to network: `forge create --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/VottingSystem.sol:VottingSystem --broadcast`
4. npm run-script "name of the Script"
### Frontend Setup
```bash
git clone https://github.com/RoxyBlockChain/VotingSystem.git
cd dapp
npm install
npm start
```

## Testing

The comprehensive Foundry test suite covers:
- Subscription and staking
- Campaign creation and management
- Voting functionality
- Result calculation and redistribution
- Edge cases and security scenarios

Run tests with:
```bash
forge test -vvv
```

## Security Considerations

1. **Stake Protection**: Funds locked during active voting periods
2. **Access Control**: Critical functions restricted to contract owner
3. **Input Validation**: All parameters validated before processing
4. **Reentrancy Protection**: Checks-effects-interactions pattern
5. **Encrypted Data**: Personal information never stored in plain text
6. **Tie Handling**: Special case for equal vote distribution

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Future Enhancements

1. Multi-chain support
2. Gas optimization improvements
3. DAO governance for campaign approval
4. IPFS integration for campaign details
5. Mobile application
6. Advanced analytics dashboard

## Contributing

Contributions are welcome! Please read our [Contribution Guidelines](CONTRIBUTING.md) before submitting pull requests.
