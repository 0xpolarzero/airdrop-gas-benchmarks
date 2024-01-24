// From: https://github.com/Anish-Agnihotri/merkle-airdrop-starter/blob/master/contracts/src/MerkleClaimERC20.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// ============ Imports ============

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // OZ: ERC20 interface
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // OZ: MerkleProof
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; // OZ: Ownable

/// @title MerkleClaimERC20
/// @notice ERC20 claimable by members of a merkle tree
/// @author Anish Agnihotri <contact@anishagnihotri.com>
/// @dev Solmate ERC20 includes unused _burn logic that can be removed to optimize deployment cost
contract MerkleClaimERC20 is Ownable {
    IERC20 public token;

    /// ============ Immutable storage ============

    /// @notice ERC20-claimee inclusion root
    bytes32 public immutable merkleRoot;

    /// ============ Mutable storage ============

    /// @notice Mapping of addresses who have claimed tokens
    mapping(address => bool) public hasClaimed;

    /// ============ Errors ============

    /// @notice Thrown if address has already claimed
    error AlreadyClaimed();
    /// @notice Thrown if address/amount are not part of Merkle tree
    error NotInMerkle();

    /// ============ Constructor ============

    /// @notice Creates a new MerkleClaimERC20 contract
    /// @param _token to be claimed
    /// @param _merkleRoot of claimees
    constructor(IERC20 _token, bytes32 _merkleRoot) Ownable(msg.sender) {
        token = _token; // Set token
        merkleRoot = _merkleRoot; // Update root
    }

    /// ============ Events ============

    /// @notice Emitted after a successful token claim
    /// @param to recipient of claim
    /// @param amount of tokens claimed
    event Claim(address indexed to, uint256 amount);

    /// ============ Functions ============

    /// @notice Allows claiming tokens if address is part of merkle tree
    /// @param to address of claimee
    /// @param amount of tokens owed to claimee
    /// @param proof merkle proof to prove address and amount are in tree
    function claim(address to, uint256 amount, bytes32[] calldata proof) external {
        // Throw if address has already claimed tokens
        if (hasClaimed[to]) revert AlreadyClaimed();

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle();

        // Set address to claimed
        hasClaimed[to] = true;

        // Transfer tokens to address
        token.transfer(to, amount);

        // Emit claim event
        emit Claim(to, amount);
    }

    /// @notice Allows to deposit tokens
    /// @dev The contract must be approved to transfer tokens before calling
    /// @param _amount of tokens to deposit
    /// Note: You could just transfer tokens directly but whatever
    function deposit(uint256 _amount) external onlyOwner {
        // Transfer tokens to contract
        token.transferFrom(msg.sender, address(this), _amount);
    }

    /// @notice Allows owner to rescue tokens
    function rescueTokens(uint256 _amount) external onlyOwner {
        // Transfer tokens to recipient
        token.transfer(msg.sender, _amount);
    }
}
