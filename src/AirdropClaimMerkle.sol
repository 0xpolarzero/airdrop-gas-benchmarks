// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Solady
import {ERC20} from "@solady/tokens/ERC20.sol";
import {ERC721} from "@solady/tokens/ERC721.sol";
import {ERC1155} from "@solady/tokens/ERC1155.sol";
import {MerkleProofLib} from "@solady/utils/MerkleProofLib.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @title AirdropClaimMerkle
/// @notice ERC20, ERC721 & ERC1155 claimable with Merkle tree
/// @dev Just an example - not audited
contract AirdropClaimMerkle is Ownable {
    ERC20 public erc20;
    ERC721 public erc721;
    ERC1155 public erc1155;

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

    /// @dev Emitted after a successful ERC20 claim
    /// @param recipient of the ERC20 tokens
    /// @param amount of tokens claimed
    event ClaimedERC20(address indexed recipient, uint256 amount);

    /// @dev Emitted after a successful ERC721 claim
    /// @param recipient of the ERC721 tokens
    /// @param tokenId of the ERC721 token claimed
    event ClaimedERC721(address indexed recipient, uint256 tokenId);

    /// @dev Emitted after a successful ERC1155 claim
    /// @param recipient of the ERC1155 tokens
    /// @param tokenId of the ERC1155 token claimed
    /// @param amount of tokens claimed
    event ClaimedERC1155(address indexed recipient, uint256 tokenId, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    /* -------------------------------- IMMUTABLE ------------------------------- */
    /// @dev ERCx-claimee inclusion root
    bytes32 public immutable merkleRoot_erc20;
    bytes32 public immutable merkleRoot_erc721;
    bytes32 public immutable merkleRoot_erc1155;

    /* ---------------------------------- STATE --------------------------------- */
    /// @dev Whether account has claimed their ERCx tokens already
    mapping(address account => bool claimed) public hasClaimed_erc20;
    mapping(address account => bool claimed) public hasClaimed_erc721;
    mapping(address account => bool claimed) public hasClaimed_erc1155;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @dev Initialize contract with token and merkle root
    /// @param _tokenERC20 to be claimed (ERC20 compatible)
    /// @param _tokenERC721 to be claimed (ERC721 compatible)
    /// @param _tokenERC1155 to be claimed (ERC1155 compatible)
    /// @param _merkleRootERC20 inclusion root for ERC20-claimees
    /// @param _merkleRootERC721 inclusion root for ERC721-claimees
    /// @param _merkleRootERC1155 inclusion root for ERC1155-claimees
    /// Note: Sets owner to deployer
    constructor(
        ERC20 _tokenERC20,
        ERC721 _tokenERC721,
        ERC1155 _tokenERC1155,
        bytes32 _merkleRootERC20,
        bytes32 _merkleRootERC721,
        bytes32 _merkleRootERC1155
    ) {
        erc20 = _tokenERC20;
        erc721 = _tokenERC721;
        erc1155 = _tokenERC1155;
        merkleRoot_erc20 = _merkleRootERC20;
        merkleRoot_erc721 = _merkleRootERC721;
        merkleRoot_erc1155 = _merkleRootERC1155;

        _initializeOwner(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Claim ERC20 tokens share as an account part of the merkle tree
    /// @param _recipient address of claimee that will receive the tokens
    /// @param _amount of tokens to claim
    /// @param _proof merkle proof to prove the 2 above parameters are part of the merkle tree
    /// Note: Uses `verifyCalldata` from `MerkleProofLib` as it is cheaper
    function claimERC20(address _recipient, uint256 _amount, bytes32[] calldata _proof) external {
        // Throw if address has already claimed tokens
        if (hasClaimed_erc20[_recipient]) revert AirdropClaimMerkle_AlreadyClaimed();

        // Generate leaf
        bytes32 leaf = keccak256(abi.encodePacked(_recipient, _amount));

        // Verify leaf is part of merkle tree given proof
        bool isValidLeaf = MerkleProofLib.verifyCalldata(_proof, merkleRoot_erc20, leaf);
        if (!isValidLeaf) revert AirdropClaimMerkle_NotInMerkle();

        // Mark account as claimed
        hasClaimed_erc20[_recipient] = true;
        // Transfer tokens to recipient
        bool success = erc20.transfer(_recipient, _amount);
        if (!success) revert AirdropClaimMerkle_TransferFailed();

        // Emit claim event
        emit ClaimedERC20(_recipient, _amount);
    }

    /// @dev Claim ERC721 token as an account part of the merkle tree
    /// @param _recipient address of claimee that will receive the token
    /// @param _tokenId of the token to claim
    /// @param _proof merkle proof to prove the 2 above parameters are part of the merkle tree
    /// Note: Uses `verifyCalldata` from `MerkleProofLib` as it is cheaper
    function claimERC721(address _recipient, uint256 _tokenId, bytes32[] calldata _proof) external {
        // Throw if address has already claimed tokens
        if (hasClaimed_erc721[_recipient]) revert AirdropClaimMerkle_AlreadyClaimed();

        // Generate leaf
        bytes32 leaf = keccak256(abi.encodePacked(_recipient, _tokenId));

        // Verify leaf is part of merkle tree given proof
        bool isValidLeaf = MerkleProofLib.verifyCalldata(_proof, merkleRoot_erc721, leaf);
        if (!isValidLeaf) revert AirdropClaimMerkle_NotInMerkle();

        // Mark account as claimed
        hasClaimed_erc721[_recipient] = true;
        // Transfer tokens to recipient
        erc721.transferFrom(address(this), _recipient, _tokenId);

        // Emit claim event
        emit ClaimedERC721(_recipient, _tokenId);
    }

    /// @dev Claim ERC1155 tokens share as an account part of the merkle tree
    /// @param _recipient address of claimee that will receive the tokens
    /// @param _tokenId of the token to claim
    /// @param _amount of tokens to claim
    /// @param _proof merkle proof to prove the 3 above parameters are part of the merkle tree
    /// Note: Uses `verifyCalldata` from `MerkleProofLib` as it is cheaper
    function claimERC1155(address _recipient, uint256 _tokenId, uint256 _amount, bytes32[] calldata _proof) external {
        // Throw if address has already claimed tokens
        if (hasClaimed_erc1155[_recipient]) revert AirdropClaimMerkle_AlreadyClaimed();

        // Generate leaf
        bytes32 leaf = keccak256(abi.encodePacked(_recipient, _tokenId, _amount));

        // Verify leaf is part of merkle tree given proof
        bool isValidLeaf = MerkleProofLib.verifyCalldata(_proof, merkleRoot_erc1155, leaf);
        if (!isValidLeaf) revert AirdropClaimMerkle_NotInMerkle();

        // Mark account as claimed
        hasClaimed_erc1155[_recipient] = true;
        // Transfer tokens to recipient
        erc1155.safeTransferFrom(address(this), _recipient, _tokenId, _amount, "");

        // Emit claim event
        emit ClaimedERC1155(_recipient, _tokenId, _amount);
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
