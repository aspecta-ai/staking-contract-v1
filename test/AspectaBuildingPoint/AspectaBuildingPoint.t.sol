// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {AspectaBuildingPoint} from "../../contracts/AspectaBuildingPoint/AspectaBuildingPoint.sol";

contract AspectaBuildingPointTest is Test {
    AspectaBuildingPoint aspectaBuildingPoint;

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
        aspectaBuildingPoint = AspectaBuildingPoint(proxy);

        assertEq(aspectaBuildingPoint.name(), "Aspecta Building Point");
    }

    function test_mint() public view {
        assertEq(aspectaBuildingPoint.name(), "Aspecta Building Point");
    }
}
