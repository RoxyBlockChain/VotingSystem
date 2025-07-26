// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VottingSystem {
    address public owner;
    uint256 public campaignCount;
    uint256 public constant MIN_STAKE = 1 ether;
    
    // Staking and subscription management
    struct Subscriber {
        bytes32 userNameHash;
        bytes32 contactHash;
        bytes32 emailHash;
        uint256 stakedAmount;
        bool isActive;
    }
    mapping(address => Subscriber) public subscribers;
    address[] public subscriberAddresses;
    uint256 public totalStaked;
    mapping(address => uint256) public lockedStake;

    // Notification management
    struct Notification {
        uint256 campaignId;
        bool acknowledged;
    }
    mapping(address => Notification[]) public userNotifications;

    // Voting campaigns
    struct Campaign {
        uint256 id;
        string title;
        string[] options;
        uint256 startTime;
        uint256 endTime;
        bool resultsPublished;
        uint256 winningOption;
        uint256 totalLosingPool;
        uint256 totalWinningStake;
        mapping(address => bool) hasVoted;
        mapping(uint256 => uint256) votesReceived;
        mapping(address => uint256) votingPower; // Voter => staked amount at voting time
        mapping(address => bool) rewardClaimed;
    }
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => string) public campaignResults;

    // Events
    event Subscribed(address indexed subscriber, uint256 amount);
    event Unsubscribed(address indexed subscriber);
    event StakeAdded(address indexed subscriber, uint256 amount);
    event StakeWithdrawn(address indexed subscriber, uint256 amount);
    event StakeLocked(address indexed subscriber, uint256 amount, uint256 campaignId);
    event NotificationSent(uint256 indexed campaignId, address indexed subscriber);
    event NotificationAcknowledged(uint256 indexed campaignId, address indexed subscriber);
    event CampaignLaunched(uint256 indexed campaignId, string title, uint256 startTime, uint256 endTime);
    event Voted(uint256 indexed campaignId, address voter, uint256 optionIndex, uint256 votingPower);
    event ResultsPublished(uint256 indexed campaignId, string result, uint256 totalLosingPool);
    event RewardClaimed(address indexed voter, uint256 campaignId, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    modifier validCampaign(uint256 campaignId) {
        require(campaignId < campaignCount, "Invalid campaign ID");
        _;
    }

    modifier onlySubscriber() {
        require(subscribers[msg.sender].isActive, "Not an active subscriber");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Subscription functions with staking
    function subscribe(
        bytes32 userNameHash,
        bytes32 contactHash,
        bytes32 emailHash
    ) external payable {
        require(!subscribers[msg.sender].isActive, "Already subscribed");
        require(msg.value >= MIN_STAKE, "Minimum 1 ETH/BNB stake required");
        
        subscribers[msg.sender] = Subscriber({
            userNameHash: userNameHash,
            contactHash: contactHash,
            emailHash: emailHash,
            stakedAmount: msg.value,
            isActive: true
        });
        
        subscriberAddresses.push(msg.sender);
        totalStaked += msg.value;
        
        emit Subscribed(msg.sender, msg.value);
    }

    function addStake() external payable onlySubscriber {
        require(msg.value > 0, "Must send positive amount");
        subscribers[msg.sender].stakedAmount += msg.value;
        totalStaked += msg.value;
        
        emit StakeAdded(msg.sender, msg.value);
    }

    function withdrawStake(uint256 amount) external onlySubscriber {
        require(amount > 0, "Amount must be positive");
        Subscriber storage sub = subscribers[msg.sender];
        uint256 availableStake = sub.stakedAmount - lockedStake[msg.sender];
        require(amount <= availableStake, "Insufficient available stake");
        
        sub.stakedAmount -= amount;
        totalStaked -= amount;
        
        payable(msg.sender).transfer(amount);
        emit StakeWithdrawn(msg.sender, amount);
    }

    function updateSubscriberInfo(
        bytes32 newUserNameHash,
        bytes32 newContactHash,
        bytes32 newEmailHash
    ) external onlySubscriber {
        Subscriber storage sub = subscribers[msg.sender];
        sub.userNameHash = newUserNameHash;
        sub.contactHash = newContactHash;
        sub.emailHash = newEmailHash;
    }

    function unsubscribe() external onlySubscriber {
        Subscriber storage sub = subscribers[msg.sender];
        require(lockedStake[msg.sender] == 0, "Cannot unsubscribe with locked stake");
        
        uint256 amount = sub.stakedAmount;
        totalStaked -= amount;
        sub.stakedAmount = 0;
        sub.isActive = false;
        
        payable(msg.sender).transfer(amount);
        emit Unsubscribed(msg.sender);
        emit StakeWithdrawn(msg.sender, amount);
    }

    // Notification management
    function acknowledgeNotification(uint256 campaignId) external validCampaign(campaignId) onlySubscriber {
        Notification[] storage notifications = userNotifications[msg.sender];
        for (uint i = 0; i < notifications.length; i++) {
            if (notifications[i].campaignId == campaignId) {
                require(!notifications[i].acknowledged, "Already acknowledged");
                notifications[i].acknowledged = true;
                emit NotificationAcknowledged(campaignId, msg.sender);
                return;
            }
        }
        revert("Notification not found");
    }

    // Campaign management
    function launchCampaign(
        string memory title,
        string[] memory options,
        uint256 startTime,
        uint256 durationInHours
    ) external onlyOwner {
        require(options.length >= 2, "At least 2 options required");
        require(startTime > block.timestamp, "Start time must be in the future");
        require(durationInHours > 0, "Duration must be positive");

        uint256 endTime = startTime + (durationInHours * 1 hours);
        uint256 campaignId = campaignCount++;
        
        Campaign storage newCampaign = campaigns[campaignId];
        newCampaign.id = campaignId;
        newCampaign.title = title;
        newCampaign.options = options;
        newCampaign.startTime = startTime;
        newCampaign.endTime = endTime;
        newCampaign.resultsPublished = false;
        
        // Create notifications for all active subscribers
        for (uint i = 0; i < subscriberAddresses.length; i++) {
            address subscriber = subscriberAddresses[i];
            if (subscribers[subscriber].isActive) {
                userNotifications[subscriber].push(Notification({
                    campaignId: campaignId,
                    acknowledged: false
                }));
                emit NotificationSent(campaignId, subscriber);
            }
        }
        
        emit CampaignLaunched(campaignId, title, startTime, endTime);
    }

    // Voting function with staked voting power
    function vote(uint256 campaignId, uint256 optionIndex) 
        external 
        validCampaign(campaignId)
        onlySubscriber
    {
        Campaign storage campaign = campaigns[campaignId];
        Subscriber storage sub = subscribers[msg.sender];
        
        require(block.timestamp >= campaign.startTime, "Voting not started");
        require(block.timestamp <= campaign.endTime, "Voting period ended");
        require(!campaign.hasVoted[msg.sender], "Already voted");
        require(optionIndex < campaign.options.length, "Invalid option index");
        require(sub.stakedAmount >= MIN_STAKE, "Insufficient stake to vote");
        
        // Check notification acknowledgment
        bool hasAcknowledged = false;
        Notification[] storage notifications = userNotifications[msg.sender];
        for (uint i = 0; i < notifications.length; i++) {
            if (notifications[i].campaignId == campaignId) {
                hasAcknowledged = notifications[i].acknowledged;
                break;
            }
        }
        require(hasAcknowledged, "Must acknowledge notification before voting");
        
        // Lock stake for redistribution
        uint256 votingPower = sub.stakedAmount;
        lockedStake[msg.sender] += votingPower;
        campaign.votingPower[msg.sender] = votingPower;
        
        campaign.hasVoted[msg.sender] = true;
        campaign.votesReceived[optionIndex] += votingPower;
        
        emit StakeLocked(msg.sender, votingPower, campaignId);
        emit Voted(campaignId, msg.sender, optionIndex, votingPower);
    }

    // Result management with redistribution
    function publishResults(uint256 campaignId) 
        external 
        onlyOwner 
        validCampaign(campaignId)
    {
        Campaign storage campaign = campaigns[campaignId];
        
        require(block.timestamp > campaign.endTime, "Voting still in progress");
        require(!campaign.resultsPublished, "Results already published");
        
        // Find winning option
        uint256 winningOption;
        uint256 winningVoteCount;
        bool isTie;
        
        for (uint i = 0; i < campaign.options.length; i++) {
            if (campaign.votesReceived[i] > winningVoteCount) {
                winningOption = i;
                winningVoteCount = campaign.votesReceived[i];
                isTie = false;
            } else if (campaign.votesReceived[i] == winningVoteCount && winningVoteCount > 0) {
                isTie = true;
            }
        }
        
        string memory result = isTie 
            ? "TIE - No redistribution" 
            : campaign.options[winningOption];
        
        // Calculate redistribution pool
        uint256 totalLosingPool = 0;
        if (!isTie) {
            for (uint i = 0; i < campaign.options.length; i++) {
                if (i != winningOption) {
                    totalLosingPool += campaign.votesReceived[i];
                }
            }
        }
        
        campaign.winningOption = winningOption;
        campaign.totalLosingPool = totalLosingPool;
        campaign.totalWinningStake = winningVoteCount;
        campaign.resultsPublished = true;
        
        campaignResults[campaignId] = result;
        emit ResultsPublished(campaignId, result, totalLosingPool);
    }

    // Claim redistribution rewards
    function claimReward(uint256 campaignId) external validCampaign(campaignId) onlySubscriber {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.resultsPublished, "Results not published");
        require(!campaign.rewardClaimed[msg.sender], "Reward already claimed");
        require(campaign.hasVoted[msg.sender], "Did not vote in this campaign");
        
        uint256 votingPower = campaign.votingPower[msg.sender];
        require(votingPower > 0, "No stake locked for this campaign");
        
        campaign.rewardClaimed[msg.sender] = true;
        
        if (campaign.winningOption == type(uint256).max) { // Handle tie
            // Unlock stake without redistribution
            lockedStake[msg.sender] -= votingPower;
            return;
        }
        
        if (campaign.votesReceived[campaign.winningOption] == 0) {
            // No winners - unlock stake
            lockedStake[msg.sender] -= votingPower;
            return;
        }
        
        if (campaign.votingPower[msg.sender] > 0) {
            // Check if voter was on winning side
            for (uint i = 0; i < campaign.options.length; i++) {
                if (i == campaign.winningOption) {
                    // Winner: receive share of losing pool
                    uint256 rewardShare = (votingPower * campaign.totalLosingPool) / campaign.totalWinningStake;
                    subscribers[msg.sender].stakedAmount += rewardShare;
                    totalStaked += rewardShare;
                    lockedStake[msg.sender] -= votingPower;
                    emit RewardClaimed(msg.sender, campaignId, rewardShare);
                } else {
                    // Loser: lose staked amount
                    subscribers[msg.sender].stakedAmount -= votingPower;
                    totalStaked -= votingPower;
                    lockedStake[msg.sender] -= votingPower;
                    emit RewardClaimed(msg.sender, campaignId, 0);
                }
            }
        }
    }

    // View functions
    function getVotes(uint256 campaignId, uint256 optionIndex) 
        external 
        view 
        validCampaign(campaignId)
        returns (uint256)
    {
        return campaigns[campaignId].votesReceived[optionIndex];
    }

    function getCampaignOptions(uint256 campaignId) 
        external 
        view 
        validCampaign(campaignId)
        returns (string[] memory)
    {
        return campaigns[campaignId].options;
    }

    function getNotifications(address user) 
        external 
        view 
        returns (Notification[] memory)
    {
        return userNotifications[user];
    }

    function getCampaignStatus(uint256 campaignId)
        external
        view
        validCampaign(campaignId)
        returns (string memory)
    {
        Campaign storage campaign = campaigns[campaignId];
        
        if (block.timestamp < campaign.startTime) {
            return "Scheduled";
        } else if (block.timestamp <= campaign.endTime) {
            return "Active";
        } else if (!campaign.resultsPublished) {
            return "Completed - Results Pending";
        } else {
            return "Completed - Results Published";
        }
    }

    function hasVoted(uint256 campaignId, address voter) 
        external 
        view 
        validCampaign(campaignId)
        returns (bool)
    {
        return campaigns[campaignId].hasVoted[voter];
    }

    function getSubscriberInfo(address subscriber) 
        external 
        view 
        returns (bytes32, bytes32, bytes32, uint256, bool) 
    {
        require(
            msg.sender == subscriber || msg.sender == owner,
            "Access denied: Only owner or subscriber can view info"
        );
        
        Subscriber memory s = subscribers[subscriber];
        return (s.userNameHash, s.contactHash, s.emailHash, s.stakedAmount, s.isActive);
    }

    function getVotingPower(address voter) external view returns (uint256) {
        return subscribers[voter].stakedAmount - lockedStake[voter];
    }

    function getLockedStake(address voter) external view returns (uint256) {
        return lockedStake[voter];
    }

    function getPotentialReward(address voter, uint256 campaignId) 
        external 
        view 
        validCampaign(campaignId)
        returns (uint256)
    {
        Campaign storage campaign = campaigns[campaignId];
        if (!campaign.resultsPublished || campaign.winningOption == type(uint256).max || 
            campaign.totalWinningStake == 0) {
            return 0;
        }
        
        uint256 votingPower = campaign.votingPower[voter];
        if (votingPower == 0) return 0;
        
        // Check if voter was on winning side
        if (campaign.votesReceived[campaign.winningOption] > 0) {
            return (votingPower * campaign.totalLosingPool) / campaign.totalWinningStake;
        }
        return 0;
    }

    // Safety function for owner to recover ETH in case of emergency
    function recoverETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance - totalStaked, "Cannot recover staked funds");
        payable(owner).transfer(amount);
    }
}