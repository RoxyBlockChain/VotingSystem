// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/VottingSystem.sol";

contract VottingSystemTest is Test {
    VottingSystem public vottingSystem;
    address owner = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);
    address user3 = address(0x4);

    bytes32 userNameHash1 = keccak256(abi.encode("User1"));
    bytes32 contactHash1 = keccak256(abi.encode("1234567890"));
    bytes32 emailHash1 = keccak256(abi.encode("user1@example.com"));

    bytes32 userNameHash2 = keccak256(abi.encode("User2"));
    bytes32 contactHash2 = keccak256(abi.encode("0987654321"));
    bytes32 emailHash2 = keccak256(abi.encode("user2@example.com"));

    bytes32 userNameHash3 = keccak256(abi.encode("User3"));
    bytes32 contactHash3 = keccak256(abi.encode("1122334455"));
    bytes32 emailHash3 = keccak256(abi.encode("user3@example.com"));

    function setUp() public {
        vm.startPrank(owner);
        vottingSystem = new VottingSystem();
        vm.stopPrank();
    }

    // Helper function to create a campaign
    function createCampaign() internal returns (uint256) {
        string[] memory options = new string[](2);
        options[0] = "Option1";
        options[1] = "Option2";
        
        vm.startPrank(owner);
        uint256 campaignId = vottingSystem.campaignCount();
        vottingSystem.launchCampaign(
            "Test Campaign",
            options,
            block.timestamp + 1 hours,
            24 // 24 hour duration
        );
        vm.stopPrank();
        
        return campaignId;
    }

    // Test subscription functionality
    function testSubscribe() public {
        vm.deal(user1, 2 ether);
        vm.startPrank(user1);
        vottingSystem.subscribe{value: 1 ether}(
            userNameHash1,
            contactHash1,
            emailHash1
        );
        vm.stopPrank();

        (, , , uint256 stakedAmount, bool isActive) = vottingSystem.getSubscriberInfo(user1);
        assertEq(stakedAmount, 1 ether);
        assertTrue(isActive);
        assertEq(vottingSystem.totalStaked(), 1 ether);
    }

    // Test subscription with insufficient stake
    function testSubscribeInsufficientStake() public {
        vm.deal(user1, 0.5 ether);
        vm.startPrank(user1);
        vm.expectRevert("Minimum 1 ETH/BNB stake required");
        vottingSystem.subscribe{value: 0.5 ether}(
            userNameHash1,
            contactHash1,
            emailHash1
        );
        vm.stopPrank();
    }

    // Test campaign creation
    // function testLaunchCampaign() public {
    //     // First subscribe users
    //     vm.deal(user1, 1 ether);
    //     vm.startPrank(user1);
    //     vottingSystem.subscribe{value: 1 ether}(
    //         userNameHash1,
    //         contactHash1,
    //         emailHash1
    //     );
    //     vm.stopPrank();

    //     string[] memory options = new string[](2);
    //     options[0] = "Option1";
    //     options[1] = "Option2";
        
    //     vm.startPrank(owner);
    //     vottingSystem.launchCampaign(
    //         "Test Campaign",
    //         options,
    //         block.timestamp + 1 hours,
    //         24
    //     );
    //     vm.stopPrank();
    //     // Verify campaign creation
    //     uint256 campaignId = 0;
    //     assertEq(vottingSystem.campaigns(campaignId)[0], campaignId);
    //     assertEq(vottingSystem.campaigns(campaignId)[1], "Test Campaign");
    //     assertEq(vottingSystem.campaigns(campaignId)[2].length, 2);
    //     assertEq(vottingSystem.campaigns(campaignId)[2][0], "Option1");
    //     assertEq(vottingSystem.campaigns(campaignId)[2][1], "Option2");
    //     assertEq(vottingSystem.campaignCount(), 1);
    // }

    // Test notification acknowledgment
    function testAcknowledgeNotification() public {
        // Subscribe user
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        vottingSystem.subscribe{value: 1 ether}(
            userNameHash1,
            contactHash1,
            emailHash1
        );
        vm.stopPrank();

        // Create campaign
        uint256 campaignId = createCampaign();
        
        // Acknowledge notification
        vm.startPrank(user1);
        vottingSystem.acknowledgeNotification(campaignId);
        vm.stopPrank();

        // Verify acknowledgment
        VottingSystem.Notification[] memory notifications = vottingSystem.getNotifications(user1);
        assertTrue(notifications[0].acknowledged);
    }

    // Test votting functionality
    function testVote() public {
        // Subscribe users
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        vottingSystem.subscribe{value: 1 ether}(
            userNameHash1,
            contactHash1,
            emailHash1
        );
        vm.stopPrank();

        vm.deal(user2, 2 ether);
        vm.startPrank(user2);
        vottingSystem.subscribe{value: 2 ether}(
            userNameHash2,
            contactHash2,
            emailHash2
        );
        vm.stopPrank();

        // Create campaign
        uint256 campaignId = createCampaign();
        
        // Acknowledge notifications
        vm.startPrank(user1);
        vottingSystem.acknowledgeNotification(campaignId);
        vm.stopPrank();
        
        vm.startPrank(user2);
        vottingSystem.acknowledgeNotification(campaignId);
        vm.stopPrank();

        // Fast forward to votting period
        vm.warp(block.timestamp + 1 hours + 1);
        
        // Vote
        vm.startPrank(user1);
        vottingSystem.vote(campaignId, 0); // Vote for Option1
        vm.stopPrank();
        
        vm.startPrank(user2);
        vottingSystem.vote(campaignId, 1); // Vote for Option2
        vm.stopPrank();

        // Check votes
        assertEq(vottingSystem.getVotes(campaignId, 0), 1 ether);
        assertEq(vottingSystem.getVotes(campaignId, 1), 2 ether);
        assertTrue(vottingSystem.hasVoted(campaignId, user1));
        assertTrue(vottingSystem.hasVoted(campaignId, user2));
    }

    // Test votting without acknowledgment
    function testVoteWithoutAcknowledgment() public {
        // Subscribe user
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        vottingSystem.subscribe{value: 1 ether}(
            userNameHash1,
            contactHash1,
            emailHash1
        );
        vm.stopPrank();

        // Create campaign
        uint256 campaignId = createCampaign();
        
        // Fast forward to votting period
        vm.warp(block.timestamp + 1 hours + 1);
        
        // Try to vote without acknowledgment
        vm.startPrank(user1);
        vm.expectRevert("Must acknowledge notification before votting");
        vottingSystem.vote(campaignId, 0);
        vm.stopPrank();
    }

    // Test stake redistribution
    function testStakeRedistribution() public {
        // Subscribe users with different stakes
        vm.deal(user1, 1 ether); // Will vote for Option1
        vm.startPrank(user1);
        vottingSystem.subscribe{value: 1 ether}(
            userNameHash1,
            contactHash1,
            emailHash1
        );
        vm.stopPrank();

        vm.deal(user2, 2 ether); // Will vote for Option1 (winning side)
        vm.startPrank(user2);
        vottingSystem.subscribe{value: 2 ether}(
            userNameHash2,
            contactHash2,
            emailHash2
        );
        vm.stopPrank();

        vm.deal(user3, 3 ether); // Will vote for Option2 (losing side)
        vm.startPrank(user3);
        vottingSystem.subscribe{value: 3 ether}(
            userNameHash3,
            contactHash3,
            emailHash3
        );
        vm.stopPrank();

        // Create campaign
        uint256 campaignId = createCampaign();
        
        // Acknowledge notifications
        vm.startPrank(user1);
        vottingSystem.acknowledgeNotification(campaignId);
        vm.stopPrank();
        
        vm.startPrank(user2);
        vottingSystem.acknowledgeNotification(campaignId);
        vm.stopPrank();
        
        vm.startPrank(user3);
        vottingSystem.acknowledgeNotification(campaignId);
        vm.stopPrank();

        // Fast forward to votting period
        vm.warp(block.timestamp + 1 hours + 1);
        
        // Vote
        vm.startPrank(user1);
        vottingSystem.vote(campaignId, 0); // Option1
        vm.stopPrank();
        
        vm.startPrank(user2);
        vottingSystem.vote(campaignId, 0); // Option1
        vm.stopPrank();
        
        vm.startPrank(user3);
        vottingSystem.vote(campaignId, 1); // Option2
        vm.stopPrank();

        // Fast forward to after votting period
        vm.warp(block.timestamp + 25 hours);
        
        // Publish results
        vm.startPrank(owner);
        vottingSystem.publishResults(campaignId);
        vm.stopPrank();

        // Check results
        assertEq(vottingSystem.campaignResults(campaignId), "Option1");
        
        // Claim rewards
        vm.startPrank(user1);
        vottingSystem.claimReward(campaignId);
        vm.stopPrank();
        
        vm.startPrank(user2);
        vottingSystem.claimReward(campaignId);
        vm.stopPrank();
        
        vm.startPrank(user3);
        vottingSystem.claimReward(campaignId);
        vm.stopPrank();

        // Check stake redistribution
        // Winners (Option1) total stake: 1 + 2 = 3 ETH
        // Losers (Option2) total stake: 3 ETH
        // Each winner gets: (their stake / winning pool) * losing pool
        
        // User1: (1/3) * 3 = 1 ETH reward
        (, , , uint256 user1Stake, ) = vottingSystem.getSubscriberInfo(user1);
        assertEq(user1Stake, 1 ether + 1 ether); // Original + reward
        
        // User2: (2/3) * 3 = 2 ETH reward
        (, , , uint256 user2Stake, ) = vottingSystem.getSubscriberInfo(user2);
        assertEq(user2Stake, 2 ether + 2 ether); // Original + reward
        
        // User3 (loser): loses entire stake
        (, , , uint256 user3Stake, ) = vottingSystem.getSubscriberInfo(user3);
        assertEq(user3Stake, 0);
        
        // Total staked should be original 6 ETH + 3 ETH redistribution = 9 ETH?
        // Actually: Winners keep their stake + get redistribution
        // User1: 1 (original) + 1 (reward) = 2
        // User2: 2 (original) + 2 (reward) = 4
        // User3: 0
        // Total: 6 ETH
        assertEq(vottingSystem.totalStaked(), 6 ether);
    }

    // Test tie scenario
    function testTieScenario() public {
        // Subscribe two users with same stake
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        vottingSystem.subscribe{value: 1 ether}(
            userNameHash1,
            contactHash1,
            emailHash1
        );
        vm.stopPrank();

        vm.deal(user2, 1 ether);
        vm.startPrank(user2);
        vottingSystem.subscribe{value: 1 ether}(
            userNameHash2,
            contactHash2,
            emailHash2
        );
        vm.stopPrank();

        // Create campaign
        uint256 campaignId = createCampaign();
        
        // Acknowledge notifications
        vm.startPrank(user1);
        vottingSystem.acknowledgeNotification(campaignId);
        vm.stopPrank();
        
        vm.startPrank(user2);
        vottingSystem.acknowledgeNotification(campaignId);
        vm.stopPrank();

        // Fast forward to votting period
        vm.warp(block.timestamp + 1 hours + 1);
        
        // Vote for different options
        vm.startPrank(user1);
        vottingSystem.vote(campaignId, 0); // Option1
        vm.stopPrank();
        
        vm.startPrank(user2);
        vottingSystem.vote(campaignId, 1); // Option2
        vm.stopPrank();

        // Fast forward to after votting period
        vm.warp(block.timestamp + 25 hours);
        
        // Publish results (should be tie)
        vm.startPrank(owner);
        vottingSystem.publishResults(campaignId);
        vm.stopPrank();

        // Check results
        assertEq(vottingSystem.campaignResults(campaignId), "TIE - No redistribution");
        
        // Claim rewards (should unlock stake without penalty/reward)
        vm.startPrank(user1);
        vottingSystem.claimReward(campaignId);
        vm.stopPrank();
        
        vm.startPrank(user2);
        vottingSystem.claimReward(campaignId);
        vm.stopPrank();

        // Check stakes remain unchanged
        (, , , uint256 user1Stake, ) = vottingSystem.getSubscriberInfo(user1);
        assertEq(user1Stake, 1 ether);
        
        (, , , uint256 user2Stake, ) = vottingSystem.getSubscriberInfo(user2);
        assertEq(user2Stake, 1 ether);
    }

    // Test stake withdrawal restrictions
    function testWithdrawDuringvotting() public {
        // Subscribe user
        vm.deal(user1, 2 ether);
        vm.startPrank(user1);
        vottingSystem.subscribe{value: 2 ether}(
            userNameHash1,
            contactHash1,
            emailHash1
        );
        vm.stopPrank();

        // Create campaign
        uint256 campaignId = createCampaign();
        
        // Acknowledge notification
        vm.startPrank(user1);
        vottingSystem.acknowledgeNotification(campaignId);
        vm.stopPrank();

        // Fast forward to votting period
        vm.warp(block.timestamp + 1 hours + 1);
        
        // Vote
        vm.startPrank(user1);
        vottingSystem.vote(campaignId, 0);
        vm.stopPrank();

        // Try to withdraw during votting period
        vm.startPrank(user1);
        vm.expectRevert("Cannot withdraw during active votting periods");
        vottingSystem.withdrawStake(1 ether);
        vm.stopPrank();
    }

    // Test emergency ETH recovery
    function testEmergencyRecovery() public {
        // Send extra ETH to contract
        vm.deal(address(vottingSystem), 5 ether);
        
        // Owner recovers ETH
        uint256 ownerBalanceBefore = owner.balance;
        vm.startPrank(owner);
        vottingSystem.recoverETH(2 ether);
        vm.stopPrank();
        
        assertEq(owner.balance, ownerBalanceBefore + 2 ether);
    }

    // Test getCampaignStatus
    function testCampaignStatus() public {
        uint256 campaignId = createCampaign();
        
        // Scheduled
        assertEq(vottingSystem.getCampaignStatus(campaignId), "Scheduled");
        
        // Active
        vm.warp(block.timestamp + 1 hours + 1);
        assertEq(vottingSystem.getCampaignStatus(campaignId), "Active");
        
        // Completed - Results Pending
        vm.warp(block.timestamp + 25 hours);
        assertEq(vottingSystem.getCampaignStatus(campaignId), "Completed - Results Pending");
        
        // Completed - Results Published
        vm.startPrank(owner);
        vottingSystem.publishResults(campaignId);
        vm.stopPrank();
        assertEq(vottingSystem.getCampaignStatus(campaignId), "Completed - Results Published");
    }
}