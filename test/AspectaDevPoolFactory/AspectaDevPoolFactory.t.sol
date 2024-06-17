// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../../contracts/AspectaDevPoolFactory/AspectaDevPoolFactory.sol";
import "../../contracts/AspectaBuildingPoint/AspectaBuildingPoint.sol";
import "../../contracts/AspectaDevPool/AspectaDevPool.sol";

contract AspectaDevPoolFactoryTest is Test {
    uint256 private constant MAX_PPB = 1e9;
    using EnumerableSet for EnumerableSet.AddressSet;

    AspectaDevPoolFactory factory;
    AspectaBuildingPoint aspToken;
    AspectaDevPool devPool;

    UpgradeableBeacon beacon;

    address asp;
    uint256 aspPK;

    address dev;
    uint256 devPK;

    address alice;
    uint256 alicePK;

    address bob;
    uint256 bobPK;

    address carol;
    uint256 carolPK;

    address derek;
    uint256 derekPK;

    function setUp() public {
        (asp, aspPK) = makeAddrAndKey("asp");
        (dev, devPK) = makeAddrAndKey("dev");
        (alice, alicePK) = makeAddrAndKey("alice");
        (bob, bobPK) = makeAddrAndKey("bob");
        (carol, carolPK) = makeAddrAndKey("carol");
        (derek, derekPK) = makeAddrAndKey("derek");

        // Start a new prank
        vm.startPrank(asp, asp);

        // Create a fork of the network
        vm.createSelectFork(vm.envString("JSON_RPC_URL"));

        // Deploy BP token
        address proxy = Upgrades.deployUUPSProxy(
            "AspectaBuildingPoint.sol",
            abi.encodeCall(AspectaBuildingPoint.initialize, asp)
        );
        aspToken = AspectaBuildingPoint(proxy);

        // Deploy beacon contract
        beacon = UpgradeableBeacon(
            Upgrades.deployBeacon("AspectaDevPool.sol", asp)
        );

        // Deploy factory contract
        address pfProxy = Upgrades.deployUUPSProxy(
            "AspectaDevPoolFactory.sol",
            abi.encodeCall(
                AspectaDevPoolFactory.initialize,
                (
                    asp,
                    address(aspToken),
                    address(beacon),
                    (3 * MAX_PPB) / 1e7,
                    1e3,
                    (6 * MAX_PPB) / 10,
                    0 seconds
                )
            )
        );
        factory = AspectaDevPoolFactory(pfProxy);

        aspToken.grantRole(aspToken.getFactoryRole(), address(factory));

        vm.stopPrank();
    }

    function testAll() public {
        /// ----------------------------------
        /// ----------- Test Stake -----------
        /// ----------------------------------

        // Assume 3 stakers stake for dev
        uint256 amount = 10 ** 18;
        uint256 aliceStakes = 1 * amount;
        uint256 bobStakes = 2 * amount;
        uint256 carolStakes = 3 * amount;

        vm.startPrank(asp, asp);
        aspToken.mint(alice, aliceStakes);
        aspToken.mint(bob, bobStakes);
        aspToken.mint(carol, carolStakes);

        // Alice stakes for dev
        vm.startPrank(alice, alice);
        factory.stake(dev, aliceStakes);
        // check pool exists
        assertNotEq(factory.getPool(dev), address(0));

        devPool = AspectaDevPool(factory.getPool(dev));
        assertEq(aliceStakes, devPool.getStakes());
        assertEq(aspToken.balanceOf(alice), 0);

        // Bob stakes for dev
        vm.startPrank(bob, bob);
        factory.stake(dev, bobStakes);
        assertEq(bobStakes, devPool.getStakes());
        assertEq(aspToken.balanceOf(bob), 0);

        // Carol stakes for dev
        vm.startPrank(carol, carol);
        factory.stake(dev, carolStakes);
        assertEq(carolStakes, devPool.getStakes());
        assertEq(aspToken.balanceOf(carol), 0);

        // Check the total stake is correct
        assertEq(
            aspToken.balanceOf(address(devPool)),
            aliceStakes + bobStakes + carolStakes
        );

        // Check the stakers have the correct shares
        uint256 aliceShares = devPool.balanceOf(alice);
        uint256 bobShares = devPool.balanceOf(bob);
        uint256 carolShares = devPool.balanceOf(carol);
        assertEq(devPool.totalSupply(), aliceShares + bobShares + carolShares);

        // Check the stakedDevSet is correct
        address[] memory aliceStakedDevs = factory.getStakedDevs(alice);
        assert(aliceStakedDevs[0] == dev);
        address[] memory bobStakedDevs = factory.getStakedDevs(bob);
        assert(bobStakedDevs[0] == dev);
        address[] memory carolStakedDevs = factory.getStakedDevs(carol);
        assert(carolStakedDevs[0] == dev);

        /// ----------------------------------
        /// -------- Test claimRewards -------
        /// ----------------------------------

        // Update the building progress
        vm.startPrank(asp, asp);
        factory.updateBuildIndex(dev, 8e9);

        // Alice claims rewards
        vm.startPrank(alice, alice);
        factory.claimStakeReward();
        assertEq(factory.getTotalClaimableStakeReward(alice), 0);

        // Dev claims rewards
        vm.startPrank(dev, dev);
        factory.claimDevReward();
        assertEq(factory.getTotalClaimableDevReward(), 0);

        /// ----------------------------------
        /// ---------- Test Withdraw ---------
        /// ----------------------------------

        // Alice withdraws
        vm.startPrank(alice, alice);
        factory.withdraw(dev);
        assertEq(devPool.getStakes(), 0);
        assertEq(aspToken.balanceOf(alice), aliceStakes);
        assertEq(devPool.balanceOf(alice), 0);
        assertEq(aspToken.balanceOf(address(devPool)), bobStakes + carolStakes);
        assertEq(devPool.totalSupply(), bobShares + carolShares);
        aliceStakedDevs = factory.getStakedDevs(alice);
        assertEq(aliceStakedDevs.length, 0);

        // Bob withdraws
        vm.startPrank(bob, bob);
        factory.withdraw(dev);
        assertEq(devPool.getStakes(), 0);
        assertEq(aspToken.balanceOf(bob), bobStakes);
        assertEq(devPool.balanceOf(bob), 0);
        assertEq(aspToken.balanceOf(address(devPool)), carolStakes);
        assertEq(devPool.totalSupply(), carolShares);
        bobStakedDevs = factory.getStakedDevs(bob);
        assertEq(bobStakedDevs.length, 0);

        // Carol withdraws
        vm.startPrank(carol, carol);
        factory.withdraw(dev);
        assertEq(devPool.getStakes(), 0);
        assertEq(aspToken.balanceOf(carol), carolStakes);
        assertEq(devPool.balanceOf(carol), 0);
        assertEq(aspToken.balanceOf(address(devPool)), 0);
        carolStakedDevs = factory.getStakedDevs(carol);
        assertEq(carolStakedDevs.length, 0);
    }

    function testAllComplex1() public {
        uint256 amount = 10 ** 18;

        vm.startPrank(asp, asp);
        aspToken.mint(alice, amount);
        aspToken.mint(bob, amount);
        aspToken.mint(carol, amount);
        aspToken.mint(derek, amount);

        // Alice stakes for dev
        vm.startPrank(alice, alice);
        factory.stake(dev, amount);

        devPool = AspectaDevPool(factory.getPool(dev));

        // Bob stakes for dev
        vm.startPrank(bob, bob);
        factory.stake(dev, amount);

        // Carol stakes for dev
        vm.startPrank(carol, carol);
        factory.stake(dev, amount);

        // Derek stakes for dev
        vm.startPrank(derek, derek);
        factory.stake(dev, amount);

        // Derek withdraws and claims rewards
        factory.getUserStakeStats(derek);
        factory.claimStakeReward();
        assertEq(aspToken.balanceOf(derek), 0);
        factory.withdraw(dev);
        assertEq(aspToken.balanceOf(derek), amount);

        // Dev claims rewards
        vm.startPrank(dev, dev);
        uint256 devRewards = aspToken.balanceOf(dev);
        assertEq(devRewards, 0);
        factory.claimDevReward();
        assertEq(devRewards, 0);

        // update the building progress
        vm.startPrank(asp, asp);
        factory.updateBuildIndex(dev, 8e9);

        // update block timesteap
        vm.roll(vm.getBlockNumber() + 30000); // nearly 1 day (3 seconds per block)

        // Carol withdraws and claims rewards
        vm.startPrank(carol, carol);
        factory.claimStakeReward();
        uint256 carolReward = aspToken.balanceOf(carol);
        assertNotEq(carolReward, 0);
        aspToken.burn(carolReward);
        factory.withdraw(dev);
        assertEq(aspToken.balanceOf(carol), amount);

        // update the building progress
        vm.startPrank(asp, asp);
        factory.updateBuildIndex(dev, 8e9);

        // update block timesteap
        vm.roll(vm.getBlockNumber() + 30000); // nearly 1 day (3 seconds per block)

        // Dev claims rewards
        vm.startPrank(dev, dev);
        factory.claimDevReward();
        assertGt(aspToken.balanceOf(dev) - devRewards, devRewards);
        devRewards = aspToken.balanceOf(dev) - devRewards;

        // Bob withdraws and claims rewards
        vm.startPrank(bob, bob);
        factory.claimStakeReward();
        uint256 bobReward = aspToken.balanceOf(bob);
        assertNotEq(bobReward, 0);
        assertGt(bobReward, carolReward);
        aspToken.burn(bobReward);
        factory.withdraw(dev);
        assertEq(aspToken.balanceOf(bob), amount);

        // update the building progress
        vm.startPrank(asp, asp);
        factory.updateBuildIndex(dev, 8e9);

        // update block timesteap
        vm.roll(vm.getBlockNumber() + 30000); // nearly 1 day (3 seconds per block)

        // Dev claims rewards
        vm.startPrank(dev, dev);
        factory.claimDevReward();
        assertGt(devRewards, aspToken.balanceOf(dev) - devRewards);
        devRewards = aspToken.balanceOf(dev) - devRewards;

        // Alice withdraws and claims rewards
        vm.startPrank(alice, alice);
        factory.claimStakeReward();
        uint256 aliceReward = aspToken.balanceOf(alice);
        assertNotEq(aliceReward, 0);
        assertGt(aliceReward, bobReward);
        assertGt(bobReward, carolReward);
        aspToken.burn(aliceReward);
        factory.withdraw(dev);
        assertEq(aspToken.balanceOf(alice), amount);

        assertGt(aliceReward / 3, bobReward / 2);
        assertGt(bobReward / 2, carolReward);
    }

    function testAllComplex2() public {
        uint256 amount = 10 ** 18;

        vm.startPrank(asp, asp);
        aspToken.mint(alice, amount);
        aspToken.mint(bob, amount);
        aspToken.mint(carol, amount);

        // Alice stakes for dev
        vm.startPrank(alice, alice);
        factory.stake(dev, amount);

        // update the building progress
        vm.startPrank(asp, asp);
        factory.updateBuildIndex(dev, 8e9);

        // update block timesteap
        vm.roll(vm.getBlockNumber() + 30000); // nearly 1 day (3 seconds per block)

        // Bob stakes for dev
        vm.startPrank(bob, bob);
        factory.stake(dev, amount);

        // update the building progress
        vm.startPrank(asp, asp);
        factory.updateBuildIndex(dev, 8e9);

        // update block timesteap
        vm.roll(vm.getBlockNumber() + 30000); // nearly 1 day (3 seconds per block)

        // Carol stakes for dev
        vm.startPrank(carol, carol);
        factory.stake(dev, amount);

        // update the building progress
        vm.startPrank(asp, asp);
        factory.updateBuildIndex(dev, 8e9);

        // update block timesteap
        vm.roll(vm.getBlockNumber() + 30000); // nearly 1 day (3 seconds per block)

        // Carol withdraws and claims rewards
        vm.startPrank(carol, carol);
        factory.claimStakeReward();
        uint256 carolReward = aspToken.balanceOf(carol);

        // Bob withdraws and claims rewards
        vm.startPrank(bob, bob);
        factory.claimStakeReward();
        uint256 bobReward = aspToken.balanceOf(bob);

        // Alice withdraws and claims rewards
        vm.startPrank(alice, alice);
        factory.claimStakeReward();
        uint256 aliceReward = aspToken.balanceOf(alice);

        assertGt(aliceReward, bobReward);
        assertGt(bobReward, carolReward);

        assertGt(aliceReward - bobReward, bobReward);
        assertGt(
            aliceReward - bobReward - carolReward,
            bobReward - carolReward
        );
    }

    function testAllComplex3() public {
        uint256 amount = 10 ** 18;

        vm.startPrank(asp, asp);
        aspToken.mint(alice, amount);

        // Alice stakes for dev
        vm.startPrank(alice, alice);
        factory.stake(dev, amount);

        // update the building progress
        vm.startPrank(asp, asp);
        factory.updateBuildIndex(dev, 8e9);

        // update block timesteap
        vm.roll(vm.getBlockNumber() + 30000); // nearly 1 day (3 seconds per block)

        vm.startPrank(dev, dev);
        factory.claimDevReward();
        aspToken.burn(aspToken.balanceOf(dev));

        // Alice withdraws and claims rewards
        vm.startPrank(alice, alice);
        factory.claimStakeReward();
        uint256 aliceReward = aspToken.balanceOf(alice);
        factory.withdraw(dev);
        aspToken.burn(aspToken.balanceOf(alice) - aliceReward);

        // update the building progress
        vm.startPrank(asp, asp);
        factory.updateBuildIndex(dev, 8e9);

        // update block timesteap
        vm.roll(vm.getBlockNumber() + 30000); // nearly 1 day (3 seconds per block)

        // Check the dev reward is 0, because no one stakes for dev in this round
        vm.startPrank(dev, dev);
        factory.claimDevReward();
        assertEq(aspToken.balanceOf(dev), 0);

        // Alice withdraws and claims rewards
        vm.startPrank(alice, alice);
        factory.claimStakeReward();
        // Balance should not change
        assertEq(aspToken.balanceOf(alice), aliceReward);

        vm.startPrank(asp, asp);
        aspToken.mint(alice, amount);

        // Alice stakes for dev again
        vm.startPrank(alice, alice);
        factory.stake(dev, amount);

        // update the building progress
        vm.startPrank(asp, asp);
        factory.updateBuildIndex(dev, 8e9);

        // update block timesteap
        vm.roll(vm.getBlockNumber() + 30000); // nearly 1 day (3 seconds per block)

        // Alice withdraws and claims rewards
        vm.startPrank(alice, alice);
        factory.claimStakeReward();
        assertEq(aliceReward, aspToken.balanceOf(alice) - aliceReward);
    }

    function testClaimDevRewardsButNotADev() public {
        vm.startPrank(alice, alice);

        vm.expectRevert("AspectaDevPoolFactory: Pool does not exist for dev");
        factory.claimDevReward();

        assertEq(aspToken.balanceOf(alice), 0);
    }

    function testClaimDevRewardsButNotStakeAnyDev() public {
        vm.startPrank(alice, alice);
        factory.claimStakeReward();

        assertEq(aspToken.balanceOf(alice), 0);
    }

    function testNonExistPoolWithdraw() public {
        vm.startPrank(asp, asp);
        vm.expectRevert();
        factory.withdraw(dev);
    }

    function testNonOperatorEmits() public {
        vm.startPrank(alice, alice);
        vm.expectRevert();
        factory.emitDevRewardClaimed(dev, 100);
    }

    function testNonOwnerUpdateBuildIndex() public {
        vm.startPrank(alice, alice);
        vm.expectRevert();
        factory.updateBuildIndex(dev, 100);
    }

    function testGetDefaultLockPeriod() public view {
        assertEq(factory.getDefaultLockPeriod(), 0);
    }

    function testGetUserStakeStats() public {
        /// -------- Test stake stats --------
        uint256 unitTime = 300;
        uint256 mintAmount = 1000e18;
        uint256 aliceStakes = mintAmount / 10;

        vm.startPrank(asp, asp);
        aspToken.mint(alice, mintAmount);

        // Alice stakes for dev
        vm.startPrank(alice, alice);
        factory.stake(dev, aliceStakes);

        // Update the building progress
        vm.startPrank(asp, asp);
        factory.updateBuildIndex(dev, 8e9);

        vm.roll(block.number + unitTime);

        // Check alice stake stats
        (
            uint256 aliceBalance,
            uint256 aliceTotalStaking,
            uint256 aliceTotalStaked,
            uint256 aliceUnclaimedStakingRewards,
            uint256 aliceUnclaimedStakedRewards
        ) = factory.getUserStakeStats(alice);

        assertEq(aliceBalance, mintAmount - aliceStakes);
        assertEq(aliceTotalStaking, aliceStakes);
        assertEq(aliceTotalStaked, 0);
        assertGt(aliceUnclaimedStakingRewards, 0);
        assertEq(aliceUnclaimedStakedRewards, 0);

        // Check alice's stats after claiming rewards
        vm.startPrank(alice, alice);
        factory.claimStakeReward();

        uint256 aliceBalance1;
        uint256 aliceTotalStaking1;
        uint256 aliceUnclaimedStakingRewards1;
        (
            aliceBalance1,
            aliceTotalStaking1,
            aliceTotalStaked,
            aliceUnclaimedStakingRewards1,
            aliceUnclaimedStakedRewards
        ) = factory.getUserStakeStats(alice);

        assertEq(aliceBalance1, aliceBalance + aliceUnclaimedStakingRewards);
        assertEq(aliceTotalStaking1, aliceTotalStaking);
        assertEq(aliceTotalStaked, 0);
        assertEq(aliceUnclaimedStakingRewards1, 0);
        assertEq(aliceUnclaimedStakedRewards, 0);

        // Check dev's stats before withdrawing
        (
            uint256 devBalance,
            uint256 devTotalStaking,
            uint256 devTotalStaked,
            uint256 devUnclaimedStakingRewards,
            uint256 devUnclaimedStakedRewards
        ) = factory.getUserStakeStats(dev);

        assertEq(devBalance, 0);
        assertEq(devTotalStaking, 0);
        assertEq(devTotalStaked, aliceStakes);
        assertEq(devUnclaimedStakingRewards, 0);
        assertGt(devUnclaimedStakedRewards, 0);

        // Check alice's stats after withdrawing
        vm.startPrank(alice, alice);
        factory.withdraw(dev);

        uint256 aliceBalance2;
        (
            aliceBalance2,
            aliceTotalStaking,
            aliceTotalStaked,
            aliceUnclaimedStakingRewards,
            aliceUnclaimedStakedRewards
        ) = factory.getUserStakeStats(alice);

        assertEq(aliceBalance2, aliceBalance1 + aliceStakes);
        assertEq(aliceTotalStaking, 0);
        assertEq(aliceTotalStaked, 0);
        assertEq(aliceUnclaimedStakingRewards, 0);
        assertEq(aliceUnclaimedStakedRewards, 0);

        // Check dev's stats after withdrawing
        (
            devBalance,
            devTotalStaking,
            devTotalStaked,
            devUnclaimedStakingRewards,
            devUnclaimedStakedRewards
        ) = factory.getUserStakeStats(dev);

        assertEq(devBalance, 0);
        assertEq(devTotalStaking, 0);
        assertEq(devTotalStaked, 0);
        assertEq(devUnclaimedStakingRewards, 0);
        assertGt(devUnclaimedStakedRewards, 0);
    }

    function testGetDevsTotalStaking() public {
        uint256 amount = 1000e18;
        uint256 aliceStakes = amount;
        uint256 bobStakes = 2 * amount;
        uint256 carolStakes = 3 * amount;

        vm.startPrank(asp, asp);
        aspToken.mint(alice, aliceStakes);
        aspToken.mint(bob, bobStakes);
        aspToken.mint(carol, carolStakes);

        // Alice stakes for dev
        vm.startPrank(alice, alice);
        factory.stake(alice, aliceStakes);
        // Bob stakes for dev
        vm.startPrank(bob, bob);
        factory.stake(bob, bobStakes);
        // Carol stakes for dev
        vm.startPrank(carol, carol);
        factory.stake(carol, carolStakes);

        address[] memory devs = new address[](3);
        devs[0] = alice;
        devs[1] = bob;
        devs[2] = carol;

        uint256[] memory totalStakings = factory.getDevsTotalStaking(devs);
        for (uint32 i = 0; i < totalStakings.length; i++) {
            assertEq(totalStakings[i], (i + 1) * aliceStakes);
        }

        // Clean up
        vm.startPrank(alice, alice);
        factory.withdraw(alice);
        vm.startPrank(bob, bob);
        factory.withdraw(bob);
        vm.startPrank(carol, carol);
        factory.withdraw(carol);

        assertEq(factory.getDevsTotalStaking(devs)[0], 0);
        assertEq(factory.getDevsTotalStaking(devs)[1], 0);
        assertEq(factory.getDevsTotalStaking(devs)[2], 0);
    }

    function testGetUserStakedList() public {
        uint256 mintAmount = 1000e18;
        uint256 aliceStakes = mintAmount / 10;

        vm.startPrank(asp, asp);
        aspToken.mint(alice, mintAmount);

        // Alice stakes for devs
        vm.startPrank(alice, alice);
        factory.stake(dev, aliceStakes);
        factory.stake(bob, 2 * aliceStakes);
        factory.stake(carol, 3 * aliceStakes);

        address[] memory devs = new address[](3);
        devs[0] = dev;
        devs[1] = bob;
        devs[2] = carol;

        uint256[] memory stakeAmounts = new uint256[](3);
        uint256[] memory unclaimedStakingRewards = new uint256[](3);
        uint256[] memory unlockTimes = new uint256[](3);

        (stakeAmounts, unclaimedStakingRewards, unlockTimes) = factory
            .getUserStakedList(alice, devs);

        for (uint32 i = 0; i < stakeAmounts.length; i++) {
            assertEq(stakeAmounts[i], (i + 1) * aliceStakes);
            assertEq(unclaimedStakingRewards[i], 0);
            assertEq(
                unlockTimes[i],
                block.timestamp + factory.getDefaultLockPeriod()
            );
        }
    }

    function testGetTotalStaking() public {
        uint256 amount = 1000e18;
        uint256 aliceStakes = amount;
        uint256 bobStakes = 2 * amount;
        uint256 carolStakes = 3 * amount;

        vm.startPrank(asp, asp);
        aspToken.mint(alice, aliceStakes);
        aspToken.mint(bob, bobStakes);
        aspToken.mint(carol, carolStakes);

        // Check total staking amount before stake
        assertEq(factory.getTotalStaking(), 0);

        // Alice stakes for dev
        vm.startPrank(alice, alice);
        factory.stake(alice, aliceStakes);
        assertEq(factory.getTotalStaking(), aliceStakes);

        // Bob stakes for dev
        vm.startPrank(bob, bob);
        factory.stake(bob, bobStakes);
        assertEq(factory.getTotalStaking(), aliceStakes + bobStakes);

        // Carol stakes for dev
        vm.startPrank(carol, carol);
        factory.stake(carol, carolStakes);
        assertEq(
            factory.getTotalStaking(),
            aliceStakes + bobStakes + carolStakes
        );

        // Clean up
        vm.startPrank(alice, alice);
        factory.withdraw(alice);
        assertEq(factory.getTotalStaking(), bobStakes + carolStakes);

        vm.startPrank(bob, bob);
        factory.withdraw(bob);
        assertEq(factory.getTotalStaking(), carolStakes);

        vm.startPrank(carol, carol);
        factory.withdraw(carol);
        assertEq(factory.getTotalStaking(), 0);
    }

    function testGetBeacon() public view {
        assertEq(factory.getBeacon(), address(beacon));
    }

    function testGetImplementation() public view {
        assertEq(factory.getImplementation(), beacon.implementation());
    }

    function testSetDefaultInflationRate() public {
        uint256 amount = 10 ** 18;

        vm.startPrank(asp, asp);
        aspToken.mint(alice, amount);

        // Alice stakes for dev
        vm.startPrank(alice, alice);
        factory.stake(dev, amount);

        // update the building progress
        vm.startPrank(asp, asp);
        factory.updateBuildIndex(dev, 8e9);

        // update block timesteap
        vm.roll(vm.getBlockNumber() + 30000); // nearly 1 day (3 seconds per block)

        // Alice withdraws and claims rewards
        vm.startPrank(alice, alice);
        factory.withdraw(dev);
        uint256 aliceBalance = aspToken.balanceOf(alice);

        // Update the default inflation rate
        vm.startPrank(asp, asp);
        uint256 newInflationRate = 10;
        factory.setDefaultInflationRate(newInflationRate);

        // Alice stakes for dev
        vm.startPrank(alice, alice);
        factory.stake(dev, amount);

        // update the building progress
        vm.startPrank(asp, asp);
        factory.updateBuildIndex(dev, 8e9);

        // update block timesteap
        vm.roll(vm.getBlockNumber() + 30000); // nearly 1 day (3 seconds per block)

        // Alice withdraws and claims rewards
        vm.startPrank(alice, alice);
        factory.withdraw(dev);
        uint256 newAliceBalance = aspToken.balanceOf(alice) - aliceBalance;

        assertGt(aliceBalance, newAliceBalance);
    }
}
