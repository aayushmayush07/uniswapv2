//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import "./interfaces/IUniswapV2Pair.sol";
import "./UniswapV2ERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Callee.sol";


contract UniswapPair is IUniswapV2Pair,UniswapV2ERC20{


    uint public MINIMUM_LIQUIDITY=10**3;
    bytes4 private constant SELECTOR=bytes4(keccak256(bytes('transfer(address,uint256)')));

}