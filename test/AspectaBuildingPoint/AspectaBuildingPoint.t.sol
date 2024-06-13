// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";

import "../../contracts/AspectaBuildingPoint/AspectaBuildingPoint.sol";

contract AspectaBuildingPointTest is Test {
    AspectaBuildingPoint aspBuildingPoint;

    address asp;
    uint256 aspPK;

    address alice;
    uint256 alicePK;

    address bob;
    uint256 bobPK;

    function setup() public {
        (asp, aspPK) = makeAddrAndKey("asp");

        (alice, alicePK) = makeAddrAndKey("alice");
        (bob, bobPK) = makeAddrAndKey("bob");

        // Start a new prank
        vm.startPrank(asp);

        // Create a fork of the network
        vm.createSelectFork("https://bsc-testnet-rpc.publicnode.com");

        aspBuildingPoint = new AspectaBuildingPoint(asp);
    }

}
