// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Solady
import {ERC721} from "@solady/tokens/ERC721.sol";
import {MerkleProofLib} from "@solady/utils/MerkleProofLib.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @title AirdropClaimMerkleERC721
/// @notice ERC721 claimable with Merkle tree
/// @dev Just an example - not audited
contract AirdropClaimMerkleERC721 is Ownable {
    ERC721 public token;

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev The account has already claimed their tokens
    error AirdropClaimMerkle_AlreadyClaimed();
    /// @dev The account is not part of the merkle tree
    error AirdropClaimMerkle_NotInMerkle();

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Emitted after a successful claim
    /// @param recipient of the NFT
    /// @param tokenId of the NFT claimed
    event Claimed(address indexed recipient, uint256 tokenId);

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    /* -------------------------------- IMMUTABLE ------------------------------- */
    /// @dev ERC721-claimee inclusion root
    bytes32 public immutable merkleRoot;

    /* ---------------------------------- STATE --------------------------------- */
    /// @dev Whether account has claimed their NFT already
    mapping(address account => bool claimed) public hasClaimed;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @dev Initialize contract with token and merkle root
    /// @param _token to be claimed (ERC721 compatible)
    /// @param _merkleRoot inclusion root for claimees
    /// Note: Sets owner to deployer
    constructor(ERC721 _token, bytes32 _merkleRoot) {
        token = _token;
        merkleRoot = _merkleRoot;

        _initializeOwner(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Claim NFT as an account part of the merkle tree
    /// @param _recipient address of claimee that will receive the token
    /// @param _tokenId of the token to claim
    /// @param _proof merkle proof to prove the 2 above parameters are part of the merkle tree
    /// Note: Uses `verifyCalldata` from `MerkleProofLib` as it is cheaper
    function claimERC721(address _recipient, uint256 _tokenId, bytes32[] calldata _proof) external {
        // Throw if address has already claimed tokens
        if (hasClaimed[_recipient]) revert AirdropClaimMerkle_AlreadyClaimed();

        // Generate leaf
        bytes32 leaf = keccak256(abi.encodePacked(_recipient, _tokenId));

        // Verify leaf is part of merkle tree given proof
        bool isValidLeaf = MerkleProofLib.verifyCalldata(_proof, merkleRoot, leaf);
        if (!isValidLeaf) revert AirdropClaimMerkle_NotInMerkle();

        // Mark account as claimed
        hasClaimed[_recipient] = true;
        // Transfer tokens to recipient
        token.transferFrom(address(this), _recipient, _tokenId);

        // Emit claim event
        emit Claimed(_recipient, _tokenId);
    }
}
