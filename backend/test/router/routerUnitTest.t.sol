// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../script/router/DeployUniswapV2ViaRouter.s.sol"; // import the script

contract UniswapV2UnitTestViaRouter is Test {
    DeployUniswapV2ViaRouter deploy;
    UniswapV2Factory factory;
    MockERC20 USDC;
    MockERC20 AK;
    IUniswapV2Pair pair;
    address deployer;
    WETH weth;
    address expected_pair;
    Router.UniswapV2Router02 router;
    bytes32 INIT_CODE_PAIR_HASH;
    address musk = makeAddr("musk");

    function setUp() public {
        deploy = new DeployUniswapV2ViaRouter();
        deploy.run();

        factory = deploy.factory();
        weth = deploy.weth();
        USDC = deploy.tokenA();
        AK = deploy.tokenB();

        router = deploy.router();
        deployer = deploy.deployer();
        vm.deal(deployer, 100 ether);
        INIT_CODE_PAIR_HASH = factory.INIT_CODE_PAIR_HASH();
        vm.startPrank(address(deployer));
        IERC20(USDC).transfer(musk, 1000 ether);
        IERC20(AK).transfer(musk, 10000 ether);
        vm.deal(musk, 100 ether);
        vm.stopPrank();
        console2.log(address(router));
    }

    function testAddLiquidityPairCreatedToExpectedPair() public {
        expected_pair = UniswapV2Library.pairFor(
            address(factory),
            address(USDC),
            address(AK)
        );
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
        address pairy = factory.getPair(address(USDC), address(AK));
        assertEq(pairy, expected_pair);
    }

    function testReservesAfterAddingLiquidity() public {
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
        address pairy = factory.getPair(address(USDC), address(AK));
        pair = IUniswapV2Pair(pairy);
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        (uint reserveA, uint reserveB) = address(USDC) < address(AK)
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        assertEq(reserveA, 10 ether);
        assertEq(reserveB, 100 ether);
        assertApproxEqAbs(
            pair.totalSupply(),
            Math.sqrt(100 ether * 10 ether),
            1e6
        );
    }

    function testAddLiquidityETHPairCreatedToExpectedPair() public {
        expected_pair = UniswapV2Library.pairFor(
            address(factory),
            address(USDC),
            address(weth)
        );

        vm.startPrank(deployer);

        USDC.approve(address(router), 100 ether);

        router.addLiquidityETH{value: 1 ether}(
            address(USDC),
            10 ether,
            9 ether,
            1 ether,
            address(deployer),
            _getDeadlineAfter20Minutes()
        );

        vm.stopPrank();
        address pairy = factory.getPair(address(USDC), address(weth));
        assertEq(pairy, expected_pair);
    }

    function testAddLiquidityETHReservesAfterAddingLiquidity() public {
        vm.startPrank(deployer);

        USDC.approve(address(router), 100 ether);

        router.addLiquidityETH{value: 1 ether}(
            address(USDC),
            10 ether,
            9 ether,
            1 ether,
            address(deployer),
            _getDeadlineAfter20Minutes()
        );

        vm.stopPrank();
        address pairy = factory.getPair(address(USDC), address(weth));
        pair = IUniswapV2Pair(pairy);
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        (uint reserveA, uint reserveB) = address(USDC) < address(weth)
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        assertEq(reserveA, 10 ether);
        assertEq(reserveB, 1 ether);
        assertApproxEqAbs(
            pair.totalSupply(),
            Math.sqrt(10 ether * 1 ether),
            1e6
        );
    }

    function testAddLiquidityETHReservesAfterAddingLiquidityWithNonDeployer()
        public
    {
        vm.startPrank(musk);

        USDC.approve(address(router), 100 ether);

        router.addLiquidityETH{value: 1 ether}(
            address(USDC),
            10 ether,
            9 ether,
            1 ether,
            address(musk),
            _getDeadlineAfter20Minutes()
        );

        vm.stopPrank();
        address pairy = factory.getPair(address(USDC), address(weth));
        pair = IUniswapV2Pair(pairy);
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        (uint reserveA, uint reserveB) = address(USDC) < address(weth)
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        assertEq(reserveA, 10 ether);
        assertEq(reserveB, 1 ether);
        assertApproxEqAbs(
            pair.totalSupply(),
            Math.sqrt(10 ether * 1 ether),
            1e6
        );
        assertEq(IERC20(USDC).balanceOf(musk), 990 ether);
    }

    function testRemoveLiquidity() public {
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

        address pairy = factory.getPair(address(USDC), address(AK));
        console2.log(
            "Lp tokens before deployment",
            UniswapV2Pair(pairy).balanceOf(address(deployer))
        );
        vm.startPrank(address(deployer));

        uint liquidity = UniswapV2Pair(pairy).balanceOf(address(deployer));
        uint pre_balance_USDC = IERC20(USDC).balanceOf(address(deployer));
        uint pre_balance_AK = IERC20(AK).balanceOf(address(deployer));
        uint balance0 = IERC20(USDC).balanceOf(address(pairy));
        uint balance1 = IERC20(AK).balanceOf(address(pairy));
        (uint balanceA, uint balanceB) = address(USDC) < address(AK)
            ? (balance0, balance1)
            : (balance1, balance0);
        uint _totalSupply = UniswapV2Pair(pairy).totalSupply();
        UniswapV2Pair(pairy).approve(address(router), type(uint256).max);

        router.removeLiquidity(
            address(USDC),
            address(AK),
            10 ether,
            1 ether,
            1 ether,
            address(deployer),
            _getDeadlineAfter20Minutes()
        );
        vm.stopPrank();
        uint post_balance_USDC = IERC20(USDC).balanceOf(address(deployer));
        uint post_balance_AK = IERC20(AK).balanceOf(address(deployer));

        assertEq(
            post_balance_USDC - pre_balance_USDC,
            (10 ether * balanceA) / _totalSupply
        );
        assertEq(
            post_balance_AK - pre_balance_AK,
            (10 ether * balanceB) / _totalSupply
        );

        console2.log(
            "Lp tokens after deployment",
            UniswapV2Pair(pairy).balanceOf(address(deployer))
        );
    }

    function testRemoveLiquidityWithPermit() public {
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

        // Get pair
        address pairy = factory.getPair(address(USDC), address(AK));
        pair = IUniswapV2Pair(pairy);

        // Sign permit for the exact LP liquidity we will remove
        uint liquidity = UniswapV2Pair(pairy).balanceOf(address(deployer));
        (uint8 v, bytes32 r, bytes32 s) = _signForApprovalByDeployer(
            pairy,
            10 ether
        );
        uint pre_balance_USDC = IERC20(USDC).balanceOf(address(deployer));
        uint pre_balance_AK = IERC20(AK).balanceOf(address(deployer));
        uint balance0 = IERC20(USDC).balanceOf(address(pairy));
        uint balance1 = IERC20(AK).balanceOf(address(pairy));
        (uint balanceA, uint balanceB) = address(USDC) < address(AK)
            ? (balance0, balance1)
            : (balance1, balance0);
        uint _totalSupply = UniswapV2Pair(pairy).totalSupply();

        router.removeLiquidityWithPermit(
            address(USDC),
            address(AK),
            10 ether,
            1 ether,
            1 ether,
            address(deployer),
            _getDeadlineAfter20Minutes(),
            false,
            v,
            r,
            s
        );
        vm.stopPrank();

        uint post_balance_USDC = IERC20(USDC).balanceOf(address(deployer));
        uint post_balance_AK = IERC20(AK).balanceOf(address(deployer));

        assertEq(
            post_balance_USDC - pre_balance_USDC,
            (10 ether * balanceA) / _totalSupply
        );
        assertEq(
            post_balance_AK - pre_balance_AK,
            (10 ether * balanceB) / _totalSupply
        );

        console2.log(
            "Lp tokens after deployment",
            UniswapV2Pair(pairy).balanceOf(address(deployer))
        );
    }

    function testRemoveLiquidityETHWithPermit() public {
        vm.startPrank(deployer);

        // Approve router and add liquidity (USDC + ETH)
        USDC.approve(address(router), 100 ether);

        router.addLiquidityETH{value: 1 ether}(
            address(USDC),
            10 ether,
            9 ether,
            1 ether,
            address(deployer),
            _getDeadlineAfter20Minutes()
        );

        // Get pair
        address pairy = factory.getPair(address(USDC), address(weth));
        pair = IUniswapV2Pair(pairy);

        // Sign permit for the exact LP liquidity we will remove
        uint liquidity = UniswapV2Pair(pairy).balanceOf(address(deployer));
        (uint8 v, bytes32 r, bytes32 s) = _signForApprovalByDeployer(
            pairy,
            liquidity
        );

        // Pre balances
        uint pre_balance_USDC = IERC20(USDC).balanceOf(address(deployer));
        uint pre_balance_ETH = address(deployer).balance; // ETH (native)
        uint balance0 = IERC20(USDC).balanceOf(address(pairy));
        uint balance1 = WETH(weth).balanceOf(address(pairy)); // WETH stored in pair
        (uint balanceA, uint balanceB) = address(USDC) < address(weth)
            ? (balance0, balance1)
            : (balance1, balance0);
        uint _totalSupply = UniswapV2Pair(pairy).totalSupply();

        // Call removeLiquidityETHWithPermit (router unwraps WETH -> ETH to deployer)
        router.removeLiquidityETHWithPermit(
            address(USDC),
            liquidity,
            0,
            0,
            address(deployer),
            _getDeadlineAfter20Minutes(),
            false,
            v,
            r,
            s
        );

        vm.stopPrank();

        // Post balances
        uint post_balance_USDC = IERC20(USDC).balanceOf(address(deployer));
        uint post_balance_ETH = address(deployer).balance;

        // Exact share assertions (same math as token remove test)
        // assertEq(
        //     post_balance_USDC - pre_balance_USDC,
        //     (liquidity * balanceA) / _totalSupply
        // );
        // assertEq(
        //     post_balance_ETH - pre_balance_ETH,
        //     (liquidity * balanceB) / _totalSupply
        // );

        console2.log(
            "Lp tokens after deployment",
            UniswapV2Pair(pairy).balanceOf(address(deployer))
        );
    }

    //swap tests
    function testSwapExactTokensForTokensSinglePath() public {
        vm.startPrank(deployer);

        USDC.approve(address(router), 100 ether);
        AK.approve(address(router), 10000 ether);

        router.addLiquidity(
            address(USDC),
            address(AK),
            100 ether,
            1000 ether,
            9 ether,
            90 ether,
            address(deployer),
            _getDeadlineAfter20Minutes()
        );

        vm.stopPrank();

        uint pre_balance_AK_musk = IERC20(AK).balanceOf(musk);
        vm.startPrank(musk);
        IERC20(USDC).approve(address(router), type(uint256).max);

        // ✅ FIX: allocate and declare array
        address[] memory path = new address[](2);
        path[0] = address(USDC);
        path[1] = address(AK);

        console2.log("The zero path is", path[0]);

        router.swapTokensForExactTokens(
            10 ether,
            2 ether,
            path,
            address(musk),
            _getDeadlineAfter20Minutes()
        );

        uint post_balance_AK_musk = IERC20(AK).balanceOf(musk);
        vm.stopPrank();

        assertEq(post_balance_AK_musk - pre_balance_AK_musk, 10 ether);
    }

    function _signForApprovalByDeployer(
        address _pair,
        uint256 value
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        uint ownerPrivateKey = deploy.deployerPrivateKey();
        address owner = deployer;
        address spender = address(router);

        uint256 nonce = IUniswapV2Pair(_pair).nonces(owner);
        uint256 deadline = _getDeadlineAfter20Minutes();

        bytes32 DOMAIN_SEPARATOR = UniswapV2Pair(_pair).DOMAIN_SEPARATOR();
        bytes32 PERMIT_TYPEHASH = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonce,
                        deadline
                    )
                )
            )
        );

        (v, r, s) = vm.sign(ownerPrivateKey, digest);

        return (v, r, s);
    }

    function _getDeadlineAfter20Minutes() internal view returns (uint256) {
        return block.timestamp + 20 minutes;
    }
}
