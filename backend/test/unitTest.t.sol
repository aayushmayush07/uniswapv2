// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../script/DeployUniswapV2.s.sol"; // import the script



contract UniswapV2UnitTest is Test{
    DeployUniswapV2 deploy;
    UniswapV2Factory factory;
    MockERC20 ETH;
    MockERC20 USDC;
    UniswapV2Pair pair;


    function setUp() public{
        deploy=new DeployUniswapV2();
        deploy.run();


        factory=deploy.factory();
        ETH=deploy.tokenA();
        USDC=deploy.tokenB();
        pair=UniswapV2Pair(deploy.pair());
    }


    function testMockSupply() public{
        assertEq(ETH.totalSupply(),100000 ether);
        assertEq(USDC.totalSupply(),10000000 ether);
    }




}