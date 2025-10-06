// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../script/core/DeployUniswapV2.s.sol"; // import the script

contract UniswapV2UnitTest is Test {
    DeployUniswapV2 deploy;
    UniswapV2Factory factory;
    MockERC20 ETH;
    MockERC20 USDC;
    UniswapV2Pair pair;
    address deployer;

    function setUp() public {
        deploy = new DeployUniswapV2();
        deploy.run();

        factory = deploy.factory();
        ETH = deploy.tokenA();
        USDC = deploy.tokenB();
        pair = UniswapV2Pair(deploy.pair());
        deployer = deploy.deployer();
    }

    function testETHMetadata() public view {
        assertEq(ETH.name(), "EthereumToken");
        assertEq(ETH.symbol(), "ETH");
        assertEq(ETH.decimals(), 18);
    }

    function testUSDCMetadata() public view {
        assertEq(USDC.name(), "DollarToken");
        assertEq(USDC.symbol(), "USDC");
        assertEq(USDC.decimals(), 18);
    }

    function testETHInitialSupply() public view {
        assertEq(ETH.totalSupply(), 100000 ether);
        assertEq(ETH.balanceOf(deployer), 100000 ether);
    }

    function testUSDCInitialSupply() public view {
        assertEq(USDC.totalSupply(), 100000000 ether);
        assertEq(USDC.balanceOf(deployer), 100000000 ether);
    }

    function testFactoryFeeSetter() public view {
        assertEq(factory.feeToSetter(), deployer);
        assertEq(factory.feeTo(), address(0));
        assertEq(factory.allPairsLength(), 1);
        assertEq(factory.allPairs(0), address(pair));
    }

    function testGetPairAfterCreation() public view {
        // Pair already created in deploy script
        address pair1 = factory.getPair(address(ETH), address(USDC));
        address pair2 = factory.getPair(address(USDC), address(ETH));

        assertEq(pair1, address(pair));
        assertEq(pair2, address(pair));
    }

    function testPairInitialVariables() public view {
        assertEq(pair.factory(), address(factory));
        assertEq(pair.token1(), address(ETH));
        assertEq(pair.token0(), address(USDC));
        assertEq(pair.MINIMUM_LIQUIDITY(), 1000);
    }
}
