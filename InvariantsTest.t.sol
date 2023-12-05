 // SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

////// Scope contracts //////
import "../../../../../ocean/Interactions.sol";
import "../../../../../ocean/Ocean.sol";
import "../../../../../adapters/Curve2PoolAdapter.sol";
import "../../../../../adapters/CurveTricryptoAdapter.sol";

////// Foundry cheats //////
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

import {Handler} from "./Handler.t.sol";

contract InvariantsTest is Test {

    ////// Scope Contracts //////
    Ocean public ocean;

    Curve2PoolAdapter public curve2PoolAdapter1; //instance 1
    Curve2PoolAdapter public curve2PoolAdapter2; //instance 2

    CurveTricryptoAdapter public curveTricryptoAdapter1; //instance 1
    CurveTricryptoAdapter public curveTricryptoAdapter2; //instance 2

    ////// System Actors //////
    address deployer = 0xcAcf4d840CB5D9a80e79b02e51186a966de757d9; //random address

    ///// Handler Contracts //////
    Handler public handler;

    ////// Scope Contracts Constructor Args//////


    function setUp() external {
        vm.createSelectFork("https://arb1.arbitrum.io/rpc"); // Pin to block 157114465
        vm.prank(deployer);
        ocean = new Ocean("");
        curve2PoolAdapter1 = new Curve2PoolAdapter(address(ocean), 0x7f90122BF0700F9E7e1F688fe926940E8839F353);
        curve2PoolAdapter2 = new Curve2PoolAdapter(address(ocean), 0x7f90122BF0700F9E7e1F688fe926940E8839F353);
        curveTricryptoAdapter1 = new CurveTricryptoAdapter(address(ocean), 0x960ea3e3C7FB317332d990873d354E18d7645590);
        curveTricryptoAdapter2 = new CurveTricryptoAdapter(address(ocean), 0x960ea3e3C7FB317332d990873d354E18d7645590);

        vm.prank(address(this));
        handler = new Handler(
            ocean, 
            curve2PoolAdapter1, 
            curve2PoolAdapter2, 
            curveTricryptoAdapter1, 
            curveTricryptoAdapter2
            );

        targetContract(address(handler));    
    }

    function invariant_just_for_test() public {
        console.log("just for test");
        assert(true);
    }

    ////////////////////////////////////
    ////// Ocean Invariant Tests //////
    ///////////////////////////////////






    //////////////////////////////////////////////////
    ////// Occurve2PoolAdapter1 Invariant Tests //////
    /////////////////////////////////////////////////







    ///////////////////////////////////////////////////////////////////////////////////
    ////// Occurve2PoolAdapter2 Invariant Tests (similar to Occurve2PoolAdapter1)//////
    //////////////////////////////////////////////////////////////////////////////////





    ////////////////////////////////////////////////////
    ////// curveTricryptoAdapter1 Invariant Tests //////
    ///////////////////////////////////////////////////





    /////////////////////////////////////////////////////////////////////////////////////
    ////// curveTricryptoAdapter1 Invariant Tests (similar to Occurve2PoolAdapter1)//////
    ////////////////////////////////////////////////////////////////////////////////////










}
