// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../script/router/DeployUniswapV2ViaRouter.s.sol"; // import the script

contract UniswapV2UnitTestViaRouter is Test {
    DeployUniswapV2ViaRouter deploy;
    UniswapV2Factory factory;
    MockERC20 USDC;
    MockERC20 AK;
    UniswapV2Pair pair;
    address deployer;
    WETH weth;
    address expected_pair;
    Router.UniswapV2Router02 router;
    bytes32 INIT_CODE_PAIR_HASH;


    function setUp() public {
        deploy = new DeployUniswapV2ViaRouter();
        deploy.run();

        factory = deploy.factory();
        weth = deploy.weth();
        USDC = deploy.tokenA();
        AK = deploy.tokenB();

        router = deploy.router();
        deployer = deploy.deployer();
        INIT_CODE_PAIR_HASH=factory.INIT_CODE_PAIR_HASH();
        console2.log(address(router));
        
    }

    function testAddLiquidityPairCreatedToExpectedPair() public {
   
        
        expected_pair = UniswapV2Library.pairFor(address(factory), address(USDC), address(AK));
        vm.startPrank(deployer);

        USDC.approve(address(router), 100 ether);
        AK.approve(address(router), 10000 ether);

        router.addLiquidity(
            address(USDC),
            address(AK),
            10 ether,
            100 ether,
            9 ether,
            90 ether,
            address(deployer),
            _getDeadlineAfter20Minutes()
        );

        vm.stopPrank();
        address pairy=factory.getPair(address(USDC),address(AK));
        assertEq(pairy, expected_pair);
    }

    function _getDeadlineAfter20Minutes() internal view returns (uint256) {
        return block.timestamp + 20 minutes;
    }
}
