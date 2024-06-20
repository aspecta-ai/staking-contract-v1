// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {AspectaDevPool} from "../../contracts/AspectaDevPool/AspectaDevPool.sol";
import {AspectaBuildingPoint} from "../../contracts/AspectaBuildingPoint/AspectaBuildingPoint.sol";
import {AspectaDevPoolFactory} from "../../contracts/AspectaDevPoolFactory/AspectaDevPoolFactory.sol";

contract AspectaDevPoolTest is Test {
    uint256 private constant MAX_PPB = 1e9;

    AspectaBuildingPoint aspToken;
    AspectaDevPoolFactory factory;
    AspectaDevPool devPool;

    address alice;
    uint256 alicePK;

    address bob;
    uint256 bobPK;

    address carol;
    uint256 carolPK;

    address derek;
    uint256 derekPK;

    uint256 rewardCut = (6 * MAX_PPB) / 10;

    function setUp() public {
        (alice, alicePK) = makeAddrAndKey("alice");
        (bob, bobPK) = makeAddrAndKey("bob");
        (carol, carolPK) = makeAddrAndKey("carol");
        (derek, derekPK) = makeAddrAndKey("derek");

        vm.startPrank(alice, alice);

        // Create a fork of the network
        vm.createSelectFork(vm.envString("JSON_RPC_URL"));

        // Deploy BP token
        address bpProxy = Upgrades.deployUUPSProxy(
            "AspectaBuildingPoint.sol",
            abi.encodeCall(AspectaBuildingPoint.initialize, alice)
        );
        aspToken = AspectaBuildingPoint(bpProxy);

        // Deploy beacon contract
        address beacon = Upgrades.deployBeacon("AspectaDevPool.sol", alice);

        // Deploy factory contract
        address pfProxy = Upgrades.deployUUPSProxy(
            "AspectaDevPoolFactory.sol",
            abi.encodeCall(
                AspectaDevPoolFactory.initialize,
                (
                    alice,
                    address(aspToken),
                    beacon,
                    (3 * MAX_PPB) / 1e7,
                    1e3,
                    rewardCut,
                    0 seconds
                )
            )
        );
        factory = AspectaDevPoolFactory(pfProxy);
        aspToken.grantRole(aspToken.getFactoryRole(), address(factory));

        aspToken.mint(alice, 1e18);
        factory.stake(alice, 1e18);
        factory.withdraw(alice);
        factory.updateBuildIndex(alice, 8e9);

        devPool = AspectaDevPool(factory.getPool(alice));
    }

    function equalWithTolerance(
        uint256 a,
        uint256 b,
        uint256 tolerance
    ) internal pure {
        if (a > b) {
            assertLt(a - b, tolerance);
        } else {
            assertLt(b - a, tolerance);
        }
    }

    function testStake() public {
        uint256 unitStake = 1000e18;
        uint256 unitTime = 300;
        aspToken.mint(bob, unitStake);
        aspToken.mint(carol, unitStake);
        aspToken.mint(derek, unitStake);

        /*
         * Basic stake and claim reward
         * Earlier staker should get more reward
         * New stakers don't have reward initially
         */
        // bob stakes
        vm.startPrank(bob, bob);
        devPool.stake(unitStake);
        // carol stakes
        vm.startPrank(carol, carol);
        devPool.stake(unitStake);
        // bob has more shares than carol
        assertGt(devPool.balanceOf(bob), devPool.balanceOf(carol));

        vm.roll(block.number + unitTime);

        // bob claims reward
        vm.startPrank(bob, bob);
        devPool.claimStakeReward();
        // carol claims reward
        vm.startPrank(carol, carol);
        devPool.claimStakeReward();

        // bob and carol should receive reward, no reward for new staker derek
        assertGt(aspToken.balanceOf(bob), 0);
        assertGt(aspToken.balanceOf(carol), 0);
        // bob staked earlier, should get more reward
        assertGt(aspToken.balanceOf(bob), aspToken.balanceOf(carol));

        /*
         * New stakers increases reward for earlier stakers
         */
        uint256 carolReward = aspToken.balanceOf(carol);
        // new staker derek stakes
        vm.startPrank(derek, derek);
        devPool.stake(unitStake);
        vm.roll(block.number + unitTime);

        // record derek's reward
        devPool.claimStakeReward();
        uint256 derekReward = aspToken.balanceOf(derek);

        // carol claims reward again
        vm.startPrank(carol, carol);
        devPool.claimStakeReward();

        // derek staked so reward for carol increased
        uint256 carolReward2 = aspToken.balanceOf(carol) - carolReward;
        assertGt(carolReward2, carolReward);

        /*
         * Withdraw does not effect new staker's reward at the same total stake
         */
        // bob withdraw, stake again, and claim reward after unit time
        vm.startPrank(bob, bob);
        devPool.withdraw();
        devPool.stake(unitStake);
        vm.roll(block.number + unitTime);
        uint256 bobBalance = aspToken.balanceOf(bob);
        devPool.claimStakeReward();
        // reward should be same as derek
        uint256 bobReward = aspToken.balanceOf(bob) - bobBalance;
        equalWithTolerance(bobReward, derekReward, 1e18);
    }

    function testRewardConsistency() public {
        uint256 unitStake = 1000e18;
        uint256 unitTime = 300;
        aspToken.mint(bob, unitStake);
        aspToken.mint(carol, unitStake);
        aspToken.mint(derek, unitStake);

        /*
         * Total reward should be consistent regardless of claim time
         */

        /// Case 1: claim once at the end
        // derek stakes
        vm.startPrank(derek, derek);
        devPool.stake(unitStake);
        vm.roll(block.number + unitTime);

        // bob stakes
        vm.startPrank(bob, bob);
        devPool.stake(unitStake);
        vm.roll(block.number + unitTime);

        // carol stakes
        vm.startPrank(carol, carol);
        devPool.stake(unitStake);
        vm.roll(block.number + unitTime);

        // derek claims reward
        vm.startPrank(derek, derek);
        devPool.claimStakeReward();
        uint256 derekReward = aspToken.balanceOf(derek);

        // Clean up
        devPool.withdraw();
        vm.startPrank(bob, bob);
        devPool.withdraw();
        vm.startPrank(carol, carol);
        devPool.withdraw();

        /// Case 2: claim multiple times
        // derek stakes, claim reward
        vm.startPrank(derek, derek);
        devPool.stake(unitStake);
        uint256 derekBalance = aspToken.balanceOf(derek);
        vm.roll(block.number + unitTime);
        devPool.claimStakeReward();

        // bob stakes, derek claim reward
        vm.startPrank(bob, bob);
        devPool.stake(unitStake);
        vm.roll(block.number + unitTime);
        vm.startPrank(derek, derek);
        devPool.claimStakeReward();

        // carol stakes, derek claim reward
        vm.startPrank(carol, carol);
        devPool.stake(unitStake);
        vm.roll(block.number + unitTime);
        vm.startPrank(derek, derek);
        devPool.claimStakeReward();

        /// derek should have same reward
        equalWithTolerance(
            aspToken.balanceOf(derek) - derekBalance,
            derekReward,
            1e18
        );
    }

    function testDevReward() public {
        uint256 unitStake = 1000e18;
        uint256 unitTime = 300;
        aspToken.mint(bob, unitStake);
        aspToken.mint(carol, unitStake);
        aspToken.mint(derek, unitStake);

        // bob stakes
        vm.startPrank(bob, bob);
        devPool.stake(unitStake);
        vm.roll(block.number + unitTime);

        // carol stakes
        vm.startPrank(carol, carol);
        devPool.stake(unitStake);
        vm.roll(block.number + unitTime);

        // derek stakes
        vm.startPrank(derek, derek);
        devPool.stake(unitStake);
        vm.roll(block.number + unitTime);

        // bob claims dev reward
        vm.startPrank(bob, bob);
        vm.expectRevert("AspectaDevPool: Only developer can claim dev reward");
        devPool.claimDevReward();

        // alice claims dev reward
        vm.startPrank(alice, alice);
        uint256 aliceBalance = aspToken.balanceOf(alice);
        devPool.claimDevReward();
        uint256 devReward = aspToken.balanceOf(alice) - aliceBalance;

        // alice should be the sum of dev reward / (1 - reward cut)
        vm.startPrank(bob, bob);
        devPool.claimStakeReward();
        vm.startPrank(carol, carol);
        devPool.claimStakeReward();
        vm.startPrank(derek, derek);
        devPool.claimStakeReward();
        uint256 totalReward = aspToken.balanceOf(bob) +
            aspToken.balanceOf(carol) +
            aspToken.balanceOf(derek);
        totalReward = (totalReward * rewardCut) / (MAX_PPB - rewardCut);
        equalWithTolerance(devReward, totalReward, 1e18);
    }

    /// Getter test cases
    function testGetClaimableStakeReward() public {
        uint256 unitStake = 1000e18;
        uint256 unitTime = 300;
        aspToken.mint(bob, unitStake);
        aspToken.mint(carol, unitStake);

        /*
         * Basic stake and claim reward
         * Earlier staker should get more reward
         * New stakers don't have reward initially
         */
        // bob has no reward before staking
        assertEq(devPool.getClaimableStakeReward(bob), 0);

        // bob stakes
        vm.startPrank(bob, bob);
        devPool.stake(unitStake);
        // carol stakes
        vm.startPrank(carol, carol);
        devPool.stake(unitStake);

        vm.roll(block.number + unitTime);

        uint256 bobReward = devPool.getClaimableStakeReward(bob);
        uint256 carolReward = devPool.getClaimableStakeReward(carol);

        // bob has more claimable reward than carol
        assertGt(bobReward, carolReward);

        // Clean up
        devPool.withdraw();
        vm.startPrank(bob, bob);
        devPool.withdraw();
        vm.startPrank(carol, carol);
        devPool.withdraw();

        // bob and carol should have no claimable reward
        assertEq(devPool.getClaimableStakeReward(bob), 0);
        assertEq(devPool.getClaimableStakeReward(carol), 0);

        // bob and carol's balance should be stake + reward
        assertEq(aspToken.balanceOf(bob), unitStake + bobReward);
        assertEq(aspToken.balanceOf(carol), unitStake + carolReward);
    }

    function testGetClaimableDevReward() public {
        uint256 unitStake = 1000e18;
        uint256 unitTime = 300;

        aspToken.mint(bob, unitStake);
        aspToken.mint(carol, unitStake);

        // Create a new pool
        vm.startPrank(bob, bob);
        factory.stake(bob, 1e18);
        factory.withdraw(bob);

        // Update build index
        vm.startPrank(alice, alice);
        factory.updateBuildIndex(bob, 8e9);
        devPool = AspectaDevPool(factory.getPool(bob));

        vm.roll(block.number + unitTime);

        uint256 devReward1 = devPool.getClaimableDevReward();
        assertEq(devReward1, 0);

        // carol stakes
        vm.startPrank(carol, carol);
        devPool.stake(unitStake);
        vm.roll(block.number + unitTime);

        uint256 devReward2 = devPool.getClaimableDevReward();
        assertGt(devReward2, 0);

        // bob claims dev reward
        vm.startPrank(bob, bob);
        uint256 bobBalance = aspToken.balanceOf(bob);
        devPool.claimDevReward();
        assertEq(aspToken.balanceOf(bob) - bobBalance, devReward2);
        assertEq(devPool.getClaimableDevReward(), 0);

        // dev reward grows with time
        vm.roll(block.number + unitTime);
        assertEq(devPool.getClaimableDevReward(), devReward2);

        // Clean up
        devPool.claimDevReward();
        vm.startPrank(carol, carol);
        devPool.withdraw();
        assertEq(devPool.getClaimableDevReward(), 0);
    }

    function testGetStakerState() public {
        uint256 unitStake = 1000e18;
        aspToken.mint(bob, unitStake);

        // bob stakes
        vm.startPrank(bob, bob);
        devPool.stake(unitStake);

        (uint256 stakeAmount, uint256 unlockTime) = devPool.getStakerState(bob);
        assertEq(stakeAmount, unitStake);
        assertEq(unlockTime, block.timestamp + factory.getDefaultLockPeriod());

        // Clean up
        devPool.withdraw();
        (stakeAmount, unlockTime) = devPool.getStakerState(bob);
        assertEq(stakeAmount, 0);
        assertEq(unlockTime, factory.getDefaultLockPeriod());
    }

    function testGetDevRewardStats() public {
        uint256 mintAmount = 2000e18;
        uint256 unitStake = mintAmount / 2;
        uint256 unitTime = 1000;

        // Mint token to bob and carol
        aspToken.mint(bob, mintAmount);
        aspToken.mint(carol, mintAmount);

        /// -------- Stage 1 ----------
        // bob stakes
        vm.startPrank(bob, bob);
        devPool.stake(unitStake);

        // carol stakes
        vm.startPrank(carol, carol);
        devPool.stake(unitStake);

        vm.roll(block.number + unitTime);

        // Record staker reward and dev reward
        uint256 bobReward = devPool.getClaimableStakeReward(bob);
        uint256 carolReward = devPool.getClaimableStakeReward(carol);
        uint256 devReward = devPool.getClaimableDevReward();

        assertGt(bobReward, 0);
        assertGt(carolReward, 0);
        assertGt(devReward, 0);

        /// -------- Stage 2 ----------
        // Claim reward and restake
        vm.startPrank(alice, alice);
        devPool.claimDevReward();

        vm.startPrank(bob, bob);
        devPool.claimStakeReward();
        devPool.stake(unitStake);

        vm.startPrank(carol, carol);
        devPool.claimStakeReward();
        devPool.stake(unitStake);

        vm.roll(block.number + unitTime);

        // Record staker reward and dev reward
        uint256 bobReward1 = devPool.getClaimableStakeReward(bob);
        uint256 carolReward1 = devPool.getClaimableStakeReward(carol);
        uint256 devReward1 = devPool.getClaimableDevReward();

        (
            uint256 totalReceivedReward,
            uint256 totalDistributedReward
        ) = devPool.getDevRewardStats();

        equalWithTolerance(totalReceivedReward, devReward + devReward1, 1e17);
        equalWithTolerance(
            totalDistributedReward,
            bobReward + carolReward + bobReward1 + carolReward1,
            1e17
        );
    }
}
