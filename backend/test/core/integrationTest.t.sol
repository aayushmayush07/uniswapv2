// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../script/core/DeployUniswapV2.s.sol"; // reuse your deploy script

contract UniswapV2IntegrationTest is Test {
    DeployUniswapV2 deploy;
    UniswapV2Factory factory;
    MockERC20 ETH;
    MockERC20 USDC;
    UniswapV2Pair pair;
    address deployer;

    address alice = address(0xAAA);
    address treasury = makeAddr("treasury");
    address aayushSwapper = makeAddr("aayush");

    function setUp() public {
        // Run your deploy script
        deploy = new DeployUniswapV2();
        deploy.run();

        factory = deploy.factory();
        ETH = deploy.tokenA();
        USDC = deploy.tokenB();
        pair = UniswapV2Pair(deploy.pair());
        deployer = deploy.deployer();

        // Fund Alice with both tokens
        vm.startPrank(deployer);
        ETH.transfer(alice, 100 ether);
        USDC.transfer(alice, 1000 ether);
        ETH.transfer(aayushSwapper, 100 ether);
        vm.stopPrank();

        vm.label(alice, "Alice");
    }

    function testAddLiquidityAndMint() public {
        vm.prank(deployer);
        factory.setFeeTo(treasury);

        assertEq(factory.feeTo(), treasury);

        vm.startPrank(alice);

        // Step 1: send tokens to pair
        ETH.transfer(address(pair), 10 ether);
        USDC.transfer(address(pair), 100 ether);
        (uint112 r0Before, uint112 r1Before, ) = pair.getReserves();
        assertEq(r0Before, 0);
        assertEq(r1Before, 0);
        assertEq(pair.kLast(), 0);

        // Step 2: call mint to mint LP tokens
        uint liquidity = pair.mint(alice);

        // Assertions
        assertGt(liquidity, 0, "Liquidity should be > 0");

        (uint112 r0, uint112 r1, ) = pair.getReserves();
        // Check order dynamically
        if (pair.token0() == address(ETH)) {
            assertEq(r0, 10 ether, "Reserve0 should equal ETH deposited");
            assertEq(r1, 100 ether, "Reserve1 should equal USDC deposited");
        } else {
            assertEq(r0, 100 ether, "Reserve0 should equal USDC deposited");
            assertEq(r1, 10 ether, "Reserve1 should equal ETH deposited");
        }

        assertEq(
            pair.balanceOf(alice),
            liquidity,
            "Alice should have LP tokens"
        );

        vm.stopPrank();
    }

    function testAddLiquidityAndMintTwice() public {
        vm.prank(deployer);
        factory.setFeeTo(treasury);

        assertEq(factory.feeTo(), treasury);

        vm.startPrank(alice);

        // Step 1: send tokens to pair
        ETH.transfer(address(pair), 10 ether);
        USDC.transfer(address(pair), 100 ether);
        (uint112 r0Before, uint112 r1Before, ) = pair.getReserves();
        assertEq(r0Before, 0);
        assertEq(r1Before, 0);
        assertEq(pair.kLast(), 0);

        // Step 2: call mint to mint LP tokens
        uint liquidity = pair.mint(alice);

        // Assertions
        assertGt(liquidity, 0, "Liquidity should be > 0");

        (uint112 r0, uint112 r1, ) = pair.getReserves();
        // Check order dynamically
        if (pair.token0() == address(ETH)) {
            assertEq(r0, 10 ether, "Reserve0 should equal ETH deposited");
            assertEq(r1, 100 ether, "Reserve1 should equal USDC deposited");
        } else {
            assertEq(r0, 100 ether, "Reserve0 should equal USDC deposited");
            assertEq(r1, 10 ether, "Reserve1 should equal ETH deposited");
        }

        assertEq(
            pair.balanceOf(alice),
            liquidity,
            "Alice should have LP tokens"
        );

        vm.stopPrank();

        vm.startPrank(alice);
        uint balanceOfAlice = pair.balanceOf(alice);
        ETH.transfer(address(pair), 10 ether);
        USDC.transfer(address(pair), 1 ether);
        uint liquidityTwice = pair.mint(alice);
        // Assertions
        assertGt(liquidityTwice, 0, "Liquidity should be > 0");

        assertEq(
            pair.balanceOf(alice),
            balanceOfAlice + liquidityTwice,
            "Alice should have LP tokens"
        );
    }

    function testAddLiquidityAndMintThenBurn() public {
        vm.prank(deployer);
        factory.setFeeTo(treasury);

        assertEq(factory.feeTo(), treasury);

        vm.startPrank(alice);

        // Step 1: send tokens to pair
        ETH.transfer(address(pair), 10 ether);
        USDC.transfer(address(pair), 100 ether);
        (uint112 r0Before, uint112 r1Before, ) = pair.getReserves();
        assertEq(r0Before, 0);
        assertEq(r1Before, 0);
        assertEq(pair.kLast(), 0);

        // Step 2: call mint to mint LP tokens
        uint liquidity = pair.mint(alice);

        // Assertions
        assertGt(liquidity, 0, "Liquidity should be > 0");

        (uint112 r0, uint112 r1, ) = pair.getReserves();
        // Check order dynamically
        if (pair.token0() == address(ETH)) {
            assertEq(r0, 10 ether, "Reserve0 should equal ETH deposited");
            assertEq(r1, 100 ether, "Reserve1 should equal USDC deposited");
        } else {
            assertEq(r0, 100 ether, "Reserve0 should equal USDC deposited");
            assertEq(r1, 10 ether, "Reserve1 should equal ETH deposited");
        }

        assertEq(
            pair.balanceOf(alice),
            liquidity,
            "Alice should have LP tokens"
        );
        uint nowBalanceOfAlice = pair.balanceOf(alice);
        pair.transfer(address(pair), 1e19);

        pair.burn(alice);

        assertEq(pair.balanceOf(alice), nowBalanceOfAlice - 1e19);

        vm.stopPrank();
    }

    function testAddLiquidityAndMintThenSwap() public {
        vm.prank(deployer);
        factory.setFeeTo(treasury);

        assertEq(factory.feeTo(), treasury);

        vm.startPrank(alice);

        // Step 1: send tokens to pair
        ETH.transfer(address(pair), 10 ether);
        USDC.transfer(address(pair), 100 ether);
        (uint112 r0Before, uint112 r1Before, ) = pair.getReserves();
        assertEq(r0Before, 0);
        assertEq(r1Before, 0);
        assertEq(pair.kLast(), 0);

        // Step 2: call mint to mint LP tokens
        uint liquidity = pair.mint(alice);

        // Assertions
        assertGt(liquidity, 0, "Liquidity should be > 0");

        (uint112 r0, uint112 r1, ) = pair.getReserves();
        // Check order dynamically
        if (pair.token0() == address(ETH)) {
            assertEq(r0, 10 ether, "Reserve0 should equal ETH deposited");
            assertEq(r1, 100 ether, "Reserve1 should equal USDC deposited");
        } else {
            assertEq(r0, 100 ether, "Reserve0 should equal USDC deposited");
            assertEq(r1, 10 ether, "Reserve1 should equal ETH deposited");
        }

        assertEq(
            pair.balanceOf(alice),
            liquidity,
            "Alice should have LP tokens"
        );

        vm.stopPrank();

        // Aayush swaps 10 ETH -> USDC
        vm.startPrank(aayushSwapper);

        uint usdcBefore = USDC.balanceOf(aayushSwapper);

        // transfer ETH to pair
        ETH.transfer(address(pair), 10 ether);

        // calculate expected output
        (uint112 r0AtSwap, uint112 r1AtSwap, ) = pair.getReserves();
        uint amountIn = 10 ether;
        uint reserveIn;
        uint reserveOut;

        if (pair.token0() == address(ETH)) {
            reserveIn = r0AtSwap;
            reserveOut = r1AtSwap;
        } else {
            reserveIn = r1AtSwap;
            reserveOut = r0AtSwap;
        }

        uint expectedOut = getAmountOut(amountIn, reserveIn, reserveOut);

        // do the swap
        uint amount0Out = pair.token0() == address(ETH) ? 0 : expectedOut;
        uint amount1Out = pair.token0() == address(ETH) ? expectedOut : 0;

        pair.swap(amount0Out, amount1Out, aayushSwapper, new bytes(0));

        uint usdcAfter = USDC.balanceOf(aayushSwapper);

        assertEq(
            usdcAfter - usdcBefore,
            expectedOut,
            "Aayush should get correct USDC"
        );

        vm.stopPrank();
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
