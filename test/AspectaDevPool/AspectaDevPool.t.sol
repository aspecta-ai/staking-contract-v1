// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {AspectaDevPool} from "../../contracts/AspectaDevPool/AspectaDevPool.sol";
import {AspectaBuildingPoint} from "../../contracts/AspectaBuildingPoint/AspectaBuildingPoint.sol";

contract AspectaDevPoolTest is Test {
    uint256 private constant MAX_PPM = 1e10;

    AspectaDevPool devPool;
    AspectaBuildingPoint aspToken;

    address alice;
    uint256 alicePK;

    address bob;
    uint256 bobPK;

    address carol;
    uint256 carolPK;

    address derek;
    uint256 derekPK;

    function setUp() public {
        (alice, alicePK) = makeAddrAndKey("alice");
        (bob, bobPK) = makeAddrAndKey("bob");
        (carol, carolPK) = makeAddrAndKey("carol");
        (derek, derekPK) = makeAddrAndKey("derek");

        vm.startPrank(alice);

        // Create a fork of the network
        vm.createSelectFork("https://bsc-testnet-rpc.publicnode.com");

        // Deploy ASP token
        aspToken = new AspectaBuildingPoint(address(alice));

        // Deploy AspectaProtocol contract
        devPool = new AspectaDevPool();
        devPool.initialize(
            alice,
            address(aspToken),
            (3 * MAX_PPM) / 1e7,
            1e3,
            (3 * MAX_PPM) / 10,
            MAX_PPM
        );
        devPool.updateBuildIndex(8e9);

        // Grant ASP token operater role to AspectaProtocol
        aspToken.grantRole(aspToken.getOperaterRole(), address(devPool));
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
        console.log("bob share", devPool.balanceOf(bob));
        console.log("total share", devPool.totalSupply());
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
        // bob staked earlier, should get more reward
        assertGt(aspToken.balanceOf(bob), 0);
        assertGt(aspToken.balanceOf(carol), 0);
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
        console.log("derek share", devPool.balanceOf(derek));
        console.log("total share", devPool.totalSupply());

        // carol claims reward again
        vm.startPrank(carol, carol);
        devPool.claimStakeReward();

        // derek staked so reward for carol increased
        uint256 carolReward2 = aspToken.balanceOf(carol) - carolReward;
        assertGt(carolReward2, carolReward);

        /*
         * Withdraw does not effect new staker's reward at the same total stake
         */
        // derek claims reward

        // bob withdraw, stake again, and claim reward after unit time
        vm.startPrank(bob, bob);
        devPool.withdraw();
        devPool.stake(unitStake);
        console.log("bob share", devPool.balanceOf(bob));
        console.log("total share", devPool.totalSupply());
        vm.roll(block.number + unitTime);
        uint256 bobBalance = aspToken.balanceOf(bob);
        devPool.claimStakeReward();
        // reward should be same as derek
        uint256 bobReward = aspToken.balanceOf(bob) - bobBalance;
        equalWithTolerance(bobReward, derekReward, 1e18);
    }
}
