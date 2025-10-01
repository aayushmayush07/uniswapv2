//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import "./interfaces/IUniswapV2Pair.sol";
import "./UniswapV2ERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Callee.sol";
import "./libraries/Math.sol";

contract UniswapV2Pair is UniswapV2ERC20, IUniswapV2Pair {
    uint public constant MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; //14 bytes
    uint112 private reserve1; //14 bytes  //These three consumes only single storage slow
    uint32 private blockTimeStampLast; //4 bytes

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;

    uint public kLast;

    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, "UniswapV2:Locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        return (reserve0, reserve1, blockTimeStampLast);
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        ); //equivalent to calling IERC20(token).transfer(to,value)
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "UniswapV2:Transfer_Failed"
        );
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "UniswapV2:FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
    }

    //its a function that update reserve
    function _update(
        uint balance0,
        uint balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= type(uint112).max && balance1 < type(uint112).max,
            "UniswapV2:OVERFLOW"
        );
        uint32 blockTimeStamp = uint32(block.timestamp % 2 ** 32); // every around 136 years it will overflow
        uint32 timeElapsed = blockTimeStamp - blockTimeStampLast; //still the difference would give same results so overflow doesnt affect

        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            price0CumulativeLast +=
                ((reserve1 * 1e18) / reserve0) *
                timeElapsed;
            price1CumulativeLast +=
                ((reserve0 * 1e18) / reserve1) *
                timeElapsed;
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimeStampLast = blockTimeStamp;
        emit Sync(reserve0, reserve1);
    }

    function _mintFee(
        uint112 _reserve0,
        uint112 _reserve1
    ) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; //read once to save gas
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0) * uint(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);

                if (rootK > rootKLast) {
                    uint numerator = totalSupply * (rootK - rootKLast);
                    uint denominator = (rootK * 5) + rootKLast; //approx rootK but if growth is very large it gets around 20 percent

                    uint liquidity = numerator / denominator;

                    if (liquidity > 0) {
                        _mint(feeTo, liquidity);
                    }
                }
            }
        } else if (_kLast != 0) {
            kLast = 0; //since no protocol fee hence no minting of LP token for protocol treasury
        }
    }

    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); //it would have been better to directly call reserve0 and reserve1 as timestamp is getting called unnecesarily
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));

        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        if (_totalSupply == 0) {
            liquidity = Math.sqrt((amount0 * amount1) - MINIMUM_LIQUIDITY);

            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (amount0 * _totalSupply) / _reserve0,
                (amount1 * _totalSupply) / _reserve1
            );
        }

        require(liquidity > 0, "UniswapV2:Insufficient_Liquidity_Minted");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);

        if (feeOn) {
            kLast = uint(reserve0) * uint(reserve1);
        }
        emit Mint(msg.sender, amount0, amount1);
    }

    //burn is called when you want the tokens using lp token, in that case the token from reserve is transferred and lp token you own is burned
    function burn(
        address to
    ) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); //save gas as sload for this bundle is done only once (tttal cost =3x2100 though)
        address _token0 = token0; //saves gas
        address _token1 = token1; //saves gas

        uint balance0 = IERC20(token0).balanceOf(address(this)); //address of smart contract is getting called becaue its the router that first add lp token in contract then burns using burn
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)]; //number of lptoken

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply;
        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;

        require(
            amount0 > 0 && amount1 > 0,
            "UniswapV2:INSUFFICIENT_LIQUIDITY_BURNED"
        );
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * uint(reserve1);

        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(
            amount0Out > 0 || amount1Out > 0,
            "UniswapV2:INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "UniswapV2:INSUFFICIENT_LIQUIDITY"
        );

        uint balance0;
        uint balance1;

        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, "UniswapV2:INVALID_TO");

        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);

        if (data.length > 0)
            IUniswapV2Callee(to).uniswapV2Call(
                msg.sender,
                amount0Out,
                amount1Out,
                data
            );

        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        uint amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;

        require(
            amount0In > 0 || amount1In > 0,
            "UniswapV2:INSUFFICIENT_INPUT_AMOUNT"
        );

        unchecked {
            uint balance0Adjusted = balance0 * 1000 - amount0In * 3; //frontend will ask for some extra amount if its not extra the call will fail
            uint balance1Adjusted = balance1 * 1000 - amount1In * 3;

            require(
                balance0Adjusted * balance1Adjusted >=
                    uint(_reserve0) * uint(_reserve1) * (1000 ** 2),
                "UniswapV2:K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, to);
    }

    function skim(address to) external lock {
        address _token0 = token0;
        address _token1 = token1;
        _safeTransfer(
            _token0,
            to,
            IERC20(_token0).balanceOf(address(this)) - reserve0
        );
        _safeTransfer(
            _token1,
            to,
            IERC20(_token1).balanceOf(address(this)) - reserve1
        );
    }

    // called to sync reserve  with balance
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }
}
