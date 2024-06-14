// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {AspectaBuildingPoint} from "../../contracts/AspectaBuildingPoint/AspectaBuildingPoint.sol";

contract AspectaBuildingPointTest is Test {
    AspectaBuildingPoint aspToken;

    address asp;
    uint256 aspPK;

    address alice;
    uint256 alicePK;

    address bob;
    uint256 bobPK;

    function setUp() public {
        (asp, aspPK) = makeAddrAndKey("asp");

        (alice, alicePK) = makeAddrAndKey("alice");
        (bob, bobPK) = makeAddrAndKey("bob");

        // Start a new prank
        vm.startPrank(asp);

        // Create a fork of the network
        vm.createSelectFork(vm.envString("JSON_RPC_URL"));

        // Deploy the contract & proxy
        address proxy = Upgrades.deployUUPSProxy(
            "AspectaBuildingPoint.sol",
            abi.encodeCall(AspectaBuildingPoint.initialize, asp)
        );
        aspToken = AspectaBuildingPoint(proxy);

        assertEq(aspToken.name(), "Aspecta Building Point");
    }

    function test_mint() public view {
        assertEq(aspToken.name(), "Aspecta Building Point");
    }

    function testBatchMint() public {
        uint32 batchSize = 100;
        address[] memory accounts = new address[](batchSize);
        uint256[] memory amounts = new uint256[](batchSize);

        for (uint32 i = 0; i < batchSize; i++) {
            accounts[i] = bob;
            amounts[i] = 1e17;
        }

        aspToken.batchMint(accounts, amounts);

        assertEq(aspToken.balanceOf(bob), 1e17 * batchSize);
    }
}
