// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../../src/core/UniswapV2Factory.sol";
import "../../test/mocks/TestERC20Mock.sol";
import "../../src/router/WETH9.sol";
import "../../src/router/UniswapV2Router02.sol" as Router;
import "../../src/router/libraries/UniswapV2Library.sol";

contract DeployUniswapV2ViaRouter is Script {
    address public deployer;
    WETH public weth;
    UniswapV2Factory public factory;

    MockERC20 public tokenA; //ETH
    MockERC20 public tokenB; //USDC

    Router.UniswapV2Router02 public router;

    uint256 public deployerPrivateKey;

    function run() external {
        uint256 chainId = block.chainid;

        if (chainId == 1) {
            console2.log("Deploying to Ethereum Mainnet");
            deployerPrivateKey = vm.envUint("MAINNET_PRIVATE_KEY");
        } else if (chainId == 11155111) {
            console2.log("Deploying to Sepolia Testnet");
            deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        } else if (chainId == 31337) {
            console2.log(" Deploying to Local Anvil");
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            revert("Unsupported chain  add your key mapping");
        }

        deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        //deploy wrapped ether
        weth = new WETH();

        //deploy factory
        factory = new UniswapV2Factory(deployer);

        // Deploy mock tokens
        tokenA = new MockERC20("DollarToken", "USDC", 100000 ether);
        tokenB = new MockERC20("AKToken", "AK", 100000000 ether);

        // Deploy router

        router = new Router.UniswapV2Router02(address(factory), address(weth));

        vm.stopBroadcast();

        console2.log("WETH deployed at:", address(factory));
        console2.log("TokenA deployed at:", address(tokenA));
        console2.log("TokenB deployed at:", address(tokenB));

        console2.log("Deployer address:", deployer);
        console2.log("Router address:", address(router));
    }
}
