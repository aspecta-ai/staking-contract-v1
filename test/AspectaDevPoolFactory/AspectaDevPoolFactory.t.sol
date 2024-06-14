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
    AspectaBuildingPoint aspBuildingPoint;
    AspectaDevPool devPool;

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

    function setUp() public {
        (asp, aspPK) = makeAddrAndKey("asp");
        (dev, devPK) = makeAddrAndKey("dev");
        (alice, alicePK) = makeAddrAndKey("alice");
        (bob, bobPK) = makeAddrAndKey("bob");
        (carol, carolPK) = makeAddrAndKey("carol");

        // Start a new prank
        vm.startPrank(asp, asp);

        // Create a fork of the network
        vm.createSelectFork(vm.envString("JSON_RPC_URL"));

        // Deploy BP token
        address proxy = Upgrades.deployUUPSProxy(
            "AspectaBuildingPoint.sol",
            abi.encodeCall(AspectaBuildingPoint.initialize, asp)
        );
        aspBuildingPoint = AspectaBuildingPoint(proxy);

        // Deploy beacon contract
        address beacon = Upgrades.deployBeacon("AspectaDevPool.sol", asp);

        // Deploy factory contract
        address pfProxy = Upgrades.deployUUPSProxy(
            "AspectaDevPoolFactory.sol",
            abi.encodeCall(
                AspectaDevPoolFactory.initialize,
                (
                    asp,
                    address(aspBuildingPoint),
                    address(beacon),
                    (3 * MAX_PPB) / 1e7,
                    1e3,
                    (6 * MAX_PPB) / 10,
                    0 seconds
                )
            )
        );
        factory = AspectaDevPoolFactory(pfProxy);

        aspBuildingPoint.grantRole(
            aspBuildingPoint.getFactoryRole(),
            address(factory)
        );

        vm.stopPrank();
    }

    function testAllFactory() public {
        /// ----------------------------------
        /// ----------- Test Stake -----------
        /// ----------------------------------

        // Assume 3 stakers stake for dev
        uint256 amount = 10 ** 18;
        uint256 aliceStakes = 1 * amount;
        uint256 bobStakes = 2 * amount;
        uint256 carolStakes = 3 * amount;

        vm.startPrank(asp, asp);
        aspBuildingPoint.mint(alice, aliceStakes);
        aspBuildingPoint.mint(bob, bobStakes);
        aspBuildingPoint.mint(carol, carolStakes);

        // Alice stakes for dev
        vm.startPrank(alice, alice);
        factory.stake(dev, aliceStakes);
        // check if pool exists
        assertNotEq(factory.getPool(dev), address(0));
        // assertEq(factory.allPools(0), devPool);

        devPool = AspectaDevPool(factory.getPool(dev));
        assertEq(aliceStakes, devPool.getStakes());

        // Bob stakes for dev
        vm.startPrank(bob, bob);
        factory.stake(dev, bobStakes);
        assertEq(bobStakes, devPool.getStakes());

        // Carol stakes for dev
        vm.startPrank(carol, carol);
        factory.stake(dev, carolStakes);
        assertEq(carolStakes, devPool.getStakes());

        // Check if the total stake is correct
        assertEq(
            aspBuildingPoint.balanceOf(address(devPool)),
            aliceStakes + bobStakes + carolStakes
        );

        // Check if the stakers have the correct shares
        uint256 aliceShares = devPool.balanceOf(alice);
        uint256 bobShares = devPool.balanceOf(bob);
        uint256 carolShares = devPool.balanceOf(carol);
        assertEq(devPool.totalSupply(), aliceShares + bobShares + carolShares);

        // Check if the stakedDevSet is correct
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
        assertEq(aspBuildingPoint.balanceOf(alice), aliceStakes);
        assertEq(devPool.balanceOf(alice), 0);
        assertEq(
            aspBuildingPoint.balanceOf(address(devPool)),
            bobStakes + carolStakes
        );
        assertEq(devPool.totalSupply(), bobShares + carolShares);
        aliceStakedDevs = factory.getStakedDevs(alice);
        assertEq(aliceStakedDevs.length, 0);

        // Bob withdraws
        vm.startPrank(bob, bob);
        factory.withdraw(dev);
        assertEq(devPool.getStakes(), 0);
        assertEq(aspBuildingPoint.balanceOf(bob), bobStakes);
        assertEq(devPool.balanceOf(bob), 0);
        assertEq(aspBuildingPoint.balanceOf(address(devPool)), carolStakes);
        assertEq(devPool.totalSupply(), carolShares);
        bobStakedDevs = factory.getStakedDevs(bob);
        assertEq(bobStakedDevs.length, 0);

        // Carol withdraws
        vm.startPrank(carol, carol);
        factory.withdraw(dev);
        assertEq(devPool.getStakes(), 0);
        assertEq(aspBuildingPoint.balanceOf(carol), carolStakes);
        assertEq(devPool.balanceOf(carol), 0);
        assertEq(aspBuildingPoint.balanceOf(address(devPool)), 0);
        carolStakedDevs = factory.getStakedDevs(carol);
        assertEq(carolStakedDevs.length, 0);
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
}
