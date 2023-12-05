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


contract Handler is CommonBase,  StdCheats, StdUtils, DSTest {

    //////////////////////////////
    ////// Glabal variables //////
    /////////////////////////////

    ////// System contracts //////
    Ocean ocean;

    Curve2PoolAdapter curve2PoolAdapter1; //instance 1
    Curve2PoolAdapter curve2PoolAdapter2; //instance 2

    CurveTricryptoAdapter curveTricryptoAdapter1; //instance 1
    CurveTricryptoAdapter curveTricryptoAdapter2; //instance 2

    ////// System Actors //////
    address deployer = 0xcAcf4d840CB5D9a80e79b02e51186a966de757d9;

    address UsdUsdtWhale = 0x9b64203878F24eB0CDF55c8c6fA7D08Ba0cF77E5; // USDC/USDT Whale;
    address twoPoolLpWallet = 0x641D99580f6cf034e1734287A9E8DaE4356641cA; // 2pool LP whale

    address wbtcUsdtWhale = 0x1Bb89c2e0E3989826B4B1f05c9C23dc73CbCBA4F; // WBTC/USDT whale;
    address tricryptoLPWhale = 0x54be362171c527DeD44F0B78642064c435443417; // Tricrypto LP whale

    address randomUser = 0x0b9e2F440a82148BFDdb25BEA451016fB94A3F02; // Random user with zero balance

    
    ////// System Tokens //////
    address usdcAddress = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address usdtAddress = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address wbtcAddress = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

    address internal currentActor;
    address internal adapter;

    constructor(
        Ocean _ocean, 
        Curve2PoolAdapter _curve2PoolAdapter1, 
        Curve2PoolAdapter _curve2PoolAdapter2, 
        CurveTricryptoAdapter _curveTricryptoAdapter1, 
        CurveTricryptoAdapter _curveTricryptoAdapter2
        ) public {
        ocean = _ocean;
        curve2PoolAdapter1 = _curve2PoolAdapter1;
        curve2PoolAdapter2 = _curve2PoolAdapter2;
        curveTricryptoAdapter1 = _curveTricryptoAdapter1;
        curveTricryptoAdapter2 = _curveTricryptoAdapter2;
    }


    /////////////////////////////////////////////////
    ////// Curve2PoolAdapter Wrapper Functions //////
    ////////////////////////////////////////////////
    address[] public curve2Actors;

    modifier useCurve2Actor(uint256 actorIndexSeed) {
        curve2Actors.push(UsdUsdtWhale);
        curve2Actors.push(twoPoolLpWallet);
        // curve2Actors.push(randomUser);
        // curve2Actors.push(wbtcUsdtWhale);
        // curve2Actors.push(tricryptoLPWhale);
        currentActor = curve2Actors[bound(actorIndexSeed, 0, curve2Actors.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    Curve2PoolAdapter[] public curve2PoolAdapters;

    modifier useCurve2Adapter(uint256 adapterIndexSeed) {
        curve2PoolAdapters.push(curve2PoolAdapter1);
        curve2PoolAdapters.push(curve2PoolAdapter2);
        adapter = address(curve2PoolAdapters[bound(adapterIndexSeed, 0, curve2PoolAdapters.length - 1)]);
        _;
    }

    function curve2Swap(bool toggle, uint256 amount, uint256 unwrapFee, uint256 _actorIndexSeed, uint256 _adapterIndexSeed) 
    public useCurve2Adapter(_adapterIndexSeed) useCurve2Actor(_actorIndexSeed)
    {
        vm.stopPrank();

        vm.startPrank(deployer);
        unwrapFee = bound(unwrapFee, 2000, type(uint256).max);
        ocean.changeUnwrapFee(unwrapFee);
        vm.stopPrank();

        vm.startPrank(currentActor);
        address inputAddress;
        address outputAddress;

        if (toggle) {
            inputAddress = usdcAddress;
            outputAddress = usdtAddress;
        } else {
            inputAddress = usdtAddress;
            outputAddress = usdcAddress;
        }

        // taking decimals into account
        if(1e17 > IERC20(inputAddress).balanceOf(currentActor) * 1e11) return;
        
        amount = bound(amount, 1e17, IERC20(inputAddress).balanceOf(currentActor) * 1e11);

        IERC20(inputAddress).approve(address(ocean), amount);

        uint256 prevInputBalance = IERC20(inputAddress).balanceOf(currentActor);
        uint256 prevOutputBalance = IERC20(outputAddress).balanceOf(currentActor);

        uint256 oceanPrevInputBalance = IERC20(inputAddress).balanceOf(address(ocean));
        uint256 oceanPrevOutputBalance = IERC20(outputAddress).balanceOf(address(ocean));

        Interaction[] memory interactions = new Interaction[](3);

        interactions[0] = Interaction({
            interactionTypeAndAddress: _fetchInteractionId(inputAddress, uint256(InteractionType.WrapErc20)),
            inputToken: 0,
            outputToken: 0,
            specifiedAmount: amount,
            metadata: bytes32(0)
        });

        interactions[1] = Interaction({
            interactionTypeAndAddress: _fetchInteractionId(adapter, uint256(InteractionType.ComputeOutputAmount)),
            inputToken: _calculateOceanId(inputAddress),
            outputToken: _calculateOceanId(outputAddress),
            specifiedAmount: type(uint256).max,
            metadata: bytes32(0)
        });

        interactions[2] = Interaction({
            interactionTypeAndAddress: _fetchInteractionId(outputAddress, uint256(InteractionType.UnwrapErc20)),
            inputToken: 0,
            outputToken: 0,
            specifiedAmount: type(uint256).max,
            metadata: bytes32(0)
        });

        // erc1155 token id's for balance delta
        uint256[] memory ids = new uint256[](2);
        ids[0] = _calculateOceanId(inputAddress);
        ids[1] = _calculateOceanId(outputAddress);

        ocean.doMultipleInteractions(interactions, ids);

        uint256 newInputBalance = IERC20(inputAddress).balanceOf(currentActor);
        uint256 newOutputBalance = IERC20(outputAddress).balanceOf(currentActor);

        uint256 newOceanInputBalance = IERC20(inputAddress).balanceOf(address(ocean));
        uint256 newOceanOutputBalance = IERC20(outputAddress).balanceOf(address(ocean));

        assertLt(newInputBalance, prevInputBalance);
        // assertTrue(false);
        // assert(false);
        // assertGt(newOutputBalance, prevOutputBalance);

        // assertEq(newOceanInputBalance, oceanPrevInputBalance);
        // assertEq(newOceanOutputBalance, oceanPrevOutputBalance);
    }
    /////////////////////////////////////////////////////
    ////// CurveTricryptoAdapter Wrapper Functions //////
    /////////////////////////////////////////////////////








    //////////////////////////////////////
    ////// ERC20 Wrapper Functions //////
    /////////////////////////////////////




    //////////////////////////////////////
    ////// ERC721 Wrapper Functions //////
    /////////////////////////////////////





    //////////////////////////////////////
    ////// ERC1155 Wrapper Functions /////
    /////////////////////////////////////





    /////////////////////////////////////
    ////// Ether Wrapper Functions /////
    ////////////////////////////////////





    //////////////////////////////////////////////
    ////// Malformed Token Wrapper Functions /////
    //////////////////////////////////////////////





    //////////////////////////////
    ////// Helper Functions //////
    //////////////////////////////
    function _calculateOceanId(address tokenAddress) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tokenAddress, uint256(0))));
    }

    function _fetchInteractionId(address token, uint256 interactionType) internal pure returns (bytes32) {
        uint256 packedValue = uint256(uint160(token));
        packedValue |= interactionType << 248;
        return bytes32(abi.encode(packedValue));
    }
}
