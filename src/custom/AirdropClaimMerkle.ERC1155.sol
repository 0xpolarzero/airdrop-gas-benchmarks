// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Solady
import {ERC1155} from "@solady/tokens/ERC1155.sol";
import {MerkleProofLib} from "@solady/utils/MerkleProofLib.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @title AirdropClaimMerkleERC1155
/// @notice ERC1155 claimable with Merkle tree
/// @dev Just an example - not audited
contract AirdropClaimMerkleERC1155 is Ownable {
    ERC1155 public token;

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
    /// @param recipient of the ERC1155 tokens
    /// @param tokenId of the ERC1155 token claimed
    /// @param amount of tokens claimed
    event Claimed(address indexed recipient, uint256 tokenId, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    /* -------------------------------- IMMUTABLE ------------------------------- */
    /// @dev ERC1155-claimee inclusion root
    bytes32 public immutable merkleRoot;

    /* ---------------------------------- STATE --------------------------------- */
    /// @dev Whether account has claimed their tokens already
    mapping(address account => bool claimed) public hasClaimed;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @dev Initialize contract with token and merkle root
    /// @param _token to be claimed (ERC1155 compatible)
    /// @param _merkleRoot inclusion root for claimees
    /// Note: Sets owner to deployer
    constructor(ERC1155 _token, bytes32 _merkleRoot) {
        token = _token;
        merkleRoot = _merkleRoot;

        _initializeOwner(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Claim tokens share as an account part of the merkle tree
    /// @param _recipient address of claimee that will receive the tokens
    /// @param _tokenId of the token to claim
    /// @param _amount of tokens to claim
    /// @param _proof merkle proof to prove the 3 above parameters are part of the merkle tree
    /// Note: Uses `verifyCalldata` from `MerkleProofLib` as it is cheaper
    function claimERC1155(address _recipient, uint256 _tokenId, uint256 _amount, bytes32[] calldata _proof) external {
        // Throw if address has already claimed tokens
        if (hasClaimed[_recipient]) revert AirdropClaimMerkle_AlreadyClaimed();

        // Generate leaf
        bytes32 leaf = keccak256(abi.encodePacked(_recipient, _tokenId, _amount));

        // Verify leaf is part of merkle tree given proof
        bool isValidLeaf = MerkleProofLib.verifyCalldata(_proof, merkleRoot, leaf);
        if (!isValidLeaf) revert AirdropClaimMerkle_NotInMerkle();

        // Mark account as claimed
        hasClaimed[_recipient] = true;
        // Transfer tokens to recipient
        token.safeTransferFrom(address(this), _recipient, _tokenId, _amount, "");

        // Emit claim event
        emit Claimed(_recipient, _tokenId, _amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   ERC1155                                  */
    /* -------------------------------------------------------------------------- */

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
