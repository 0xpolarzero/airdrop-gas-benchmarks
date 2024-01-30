// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Solady
import {ERC20} from "@solady/tokens/ERC20.sol";
import {MerkleProofLib} from "@solady/utils/MerkleProofLib.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @title AirdropClaimMerkle_ERC20
/// @notice ERC20 claimable with Merkle tree
/// @dev Just an example - not audited
contract AirdropClaimMerkle_ERC20 is Ownable {
    ERC20 public token;

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev The account has already claimed their tokens
    error AirdropClaimMerkle_AlreadyClaimed();
    /// @dev The account is not part of the merkle tree
    error AirdropClaimMerkle_NotInMerkle();
    /// @dev The transfer of tokens failed
    error AirdropClaimMerkle_TransferFailed();

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Emitted after a successful claim
    /// @param recipient of the ERC20 tokens
    /// @param amount of tokens claimed
    event Claimed(address indexed recipient, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    /* -------------------------------- IMMUTABLE ------------------------------- */
    /// @dev ERC20-claimee inclusion root
    bytes32 public immutable merkleRoot;

    /* ---------------------------------- STATE --------------------------------- */
    /// @dev Whether account has claimed their tokens already
    mapping(address account => bool claimed) public hasClaimed;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @dev Initialize contract with token and merkle root
    /// @param _token to be claimed (ERC20 compatible)
    /// @param _merkleRoot inclusion root for claimees
    /// Note: Sets owner to deployer
    constructor(ERC20 _token, bytes32 _merkleRoot) {
        token = _token;
        merkleRoot = _merkleRoot;

        _initializeOwner(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Claim tokens share as an account part of the merkle tree
    /// @param _recipient address of claimee that will receive the tokens
    /// @param _amount of tokens to claim
    /// @param _proof merkle proof to prove the 2 above parameters are part of the merkle tree
    /// Note: Uses `verifyCalldata` from `MerkleProofLib` as it is cheaper
    function claimERC20(address _recipient, uint256 _amount, bytes32[] calldata _proof) external {
        // Throw if address has already claimed tokens
        if (hasClaimed[_recipient]) revert AirdropClaimMerkle_AlreadyClaimed();

        // Generate leaf
        bytes32 leaf = keccak256(abi.encodePacked(_recipient, _amount));

        // Verify leaf is part of merkle tree given proof
        bool isValidLeaf = MerkleProofLib.verifyCalldata(_proof, merkleRoot, leaf);
        if (!isValidLeaf) revert AirdropClaimMerkle_NotInMerkle();

        // Mark account as claimed
        hasClaimed[_recipient] = true;
        // Transfer tokens to recipient
        bool success = token.transfer(_recipient, _amount);
        if (!success) revert AirdropClaimMerkle_TransferFailed();

        // Emit claim event
        emit Claimed(_recipient, _amount);
    }
}
