// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title Wrapped Ether (WETH)
/// @notice Minimal, modern WETH with safe ETH send and ERC-20 semantics
contract WETH {
    string public constant name = "Wrapped Ether";
    string public constant symbol = "WETH";
    uint8 public constant decimals = 18;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Deposit(address indexed to, uint256 value);
    event Withdrawal(address indexed from, uint256 value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /// @dev Receive ETH and mint WETH 1:1
    receive() external payable {
        deposit();
    }

    /// @dev Fallback disabled to avoid accidental ETH sends without mint
    fallback() external payable {
        revert("WETH: use deposit()");
    }

    /// @notice Wrap ETH into WETH (mints to msg.sender)
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
        emit Transfer(address(0), msg.sender, msg.value); // ERC20-style mint event
    }

    /// @notice Unwrap WETH into ETH (burns from msg.sender)
    function withdraw(uint256 wad) external {
        require(balanceOf[msg.sender] >= wad, "WETH: insufficient balance");

        balanceOf[msg.sender] -= wad;

        emit Withdrawal(msg.sender, wad);
        emit Transfer(msg.sender, address(0), wad); // ERC20-style burn event

        (bool ok, ) = msg.sender.call{value: wad}("");
        require(ok, "WETH: ETH transfer failed");
    }

    /// @notice Total WETH in existence equals ETH held by this contract
    function totalSupply() external view returns (uint256) {
        return address(this).balance;
    }

    function approve(address spender, uint256 wad) external returns (bool) {
        allowance[msg.sender][spender] = wad;
        emit Approval(msg.sender, spender, wad);
        return true;
    }

    function transfer(address to, uint256 wad) external returns (bool) {
        return transferFrom(msg.sender, to, wad);
    }

    function transferFrom(
        address from,
        address to,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[from] >= wad, "WETH: insufficient balance");

        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= wad, "WETH: insufficient allowance");
                allowance[from][msg.sender] = allowed - wad;
            }
        }

        balanceOf[from] -= wad;
        balanceOf[to] += wad;

        emit Transfer(from, to, wad);
        return true;
    }
}
