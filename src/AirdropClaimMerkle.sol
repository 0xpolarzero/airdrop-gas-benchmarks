// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Solady
import {ERC20} from "@solady/tokens/ERC20.sol";
import {ERC721} from "@solady/tokens/ERC721.sol";
import {MerkleProofLib} from "@solady/utils/MerkleProofLib.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @title AirdropClaimMerkle
/// @notice ERC20 & ERC721 claimable with Merkle tree
/// @dev Just an example - not audited
contract AirdropClaimMerkle is Ownable {
    ERC20 public erc20;
    ERC721 public erc721;

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

    /// @dev Emitted after a successful ERC20 claim
    /// @param recipient of the ERC20 tokens
    /// @param amount of tokens claimed
    event ClaimedERC20(address indexed recipient, uint256 amount);

    /// @dev Emitted after a successful ERC721 claim
    /// @param recipient of the ERC721 tokens
    /// @param tokenId of the ERC721 token claimed
    event ClaimedERC721(address indexed recipient, uint256 tokenId);

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    /* -------------------------------- IMMUTABLE ------------------------------- */
    /// @dev ERC20-claimee inclusion root
    bytes32 public immutable merkleRoot_erc20;
    /// @dev ERC721-claimee inclusion root
    bytes32 public immutable merkleRoot_erc721;

    /* ---------------------------------- STATE --------------------------------- */
    /// @dev Whether account has claimed ERC20 tokens already
    mapping(address account => bool claimed) public hasClaimed_erc20;
    /// @dev Whether account has claimed ERC721 tokens already
    mapping(address account => bool claimed) public hasClaimed_erc721;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @dev Initialize contract with token and merkle root
    /// @param _tokenERC20 to be claimed (ERC20 compatible)
    /// @param _tokenERC721 to be claimed (ERC721 compatible)
    /// @param _merkleRootERC20 inclusion root for ERC20-claimees
    /// @param _merkleRootERC721 inclusion root for ERC721-claimees
    /// Note: Sets owner to deployer
    constructor(ERC20 _tokenERC20, ERC721 _tokenERC721, bytes32 _merkleRootERC20, bytes32 _merkleRootERC721) {
        erc20 = _tokenERC20;
        erc721 = _tokenERC721;
        merkleRoot_erc20 = _merkleRootERC20;
        merkleRoot_erc721 = _merkleRootERC721;

        _initializeOwner(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Claim ERC20 tokens share as an account part of the merkle tree
    /// @param _recipient address of claimee
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
        erc20.transfer(_recipient, _amount);

        // Emit claim event
        emit ClaimedERC20(_recipient, _amount);
    }

    /// @dev Claim ERC721 token as an account part of the merkle tree
    /// @param _recipient address of claimee
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

    /* -------------------------------------------------------------------------- */
    /*                                  UTILITIES                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Returns a slice of `_bytes` with the first 64 bytes removed.
    /// Note: Copied from Murky: https://github.com/dmfxyz/murky/blob/main/script/common/ScriptHelper.sol#L15
    function ltrim64(bytes memory _bytes) internal pure returns (bytes memory) {
        return slice(_bytes, 64, _bytes.length - 64);
    }

    /// @dev Returns a slice of `_bytes` starting at index `_start` and of length `_length`.
    /// Note: Copied from Murky: https://github.com/dmfxyz/murky/blob/main/script/common/ScriptHelper.sol#L21
    /// referenece: https://github.com/GNSPS/solidity-bytes-utils/blob/6458fb2780a3092bc756e737f246be1de6d3d362/contracts/BytesLib.sol#L228
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                tempBytes := mload(0x40)

                let lengthmod := and(_length, 31)
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for { let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start) } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)

                mstore(tempBytes, 0)
                mstore(0x40, add(tempBytes, 0x20))
            }
        }
        return tempBytes;
    }
}
