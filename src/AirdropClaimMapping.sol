// Basic airdrop contract copied from a top gas guzzler on Etherscan.
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AirdropClaimMapping is Ownable {
    IERC20 public token;

    mapping(address => uint256) public balances;

    event Airdropped(address indexed recipient, uint256 amount);
    event Claimed(address indexed recipient, uint256 amount);
    event TokensRescued(address indexed token, address indexed recipient, uint256 amount);

    constructor(address _token) Ownable(msg.sender) {
        token = IERC20(_token);
    }

    function airdrop(address[] calldata _recipients, uint256[] calldata _values) external onlyOwner {
        require(_recipients.length == _values.length, "Mismatched input arrays");

        uint256 total = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            balances[_recipients[i]] += _values[i];
            total += _values[i];
            emit Airdropped(_recipients[i], _values[i]);
        }

        require(token.transferFrom(msg.sender, address(this), total), "Transfer failed");
    }

    function claim() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "Nothing to claim");

        balances[msg.sender] = 0;
        require(token.transfer(msg.sender, balance), "Transfer failed");
        emit Claimed(msg.sender, balance);
    }

    function rescueTokens(IERC20 _token, address _recipient, uint256 _amount) external onlyOwner {
        require(_token.transfer(_recipient, _amount), "Transfer failed");
        emit TokensRescued(address(_token), _recipient, _amount);
    }
}
