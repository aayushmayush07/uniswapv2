// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../../src/core/UniswapV2Factory.sol";
import "../../test/mocks/TestERC20Mock.sol";

contract DeployUniswapV2 is Script {
    UniswapV2Factory public factory;
    MockERC20 public tokenA; //ETH
    MockERC20 public tokenB; //USDC
    address public pair;
    address public deployer;

    function run() external {
        uint256 chainId = block.chainid;
        uint256 deployerPrivateKey;

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
        // 1. Deploy Factory
        factory = new UniswapV2Factory(deployer);

        // 2. Deploy mock tokens
        tokenA = new MockERC20("EthereumToken", "ETH", 100000 ether);
        tokenB = new MockERC20("DollarToken", "USDC", 100000000 ether);

        //Create pair
        pair = factory.createPair(address(tokenA), address(tokenB));

        // 4. Log
        console2.log("Factory deployed at:", address(factory));
        console2.log("TokenA deployed at:", address(tokenA));
        console2.log("TokenB deployed at:", address(tokenB));
        console2.log("Pair deployed at:", pair);
        console2.log("Deployer address:", deployer);

        vm.stopBroadcast();
    }
}
