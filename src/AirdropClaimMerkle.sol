// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Solady
import {ERC20} from "@solady/tokens/ERC20.sol";
import {MerkleProofLib} from "@solady/utils/MerkleProofLib.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @title AirdropClaimMerkle
/// @notice ERC20 claimable with Merkle tree
/// @dev Just an example - not audited
contract AirdropClaimMerkle is Ownable {
    ERC20 public token;

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
    /// @dev Whether account has claimed tokens already
    mapping(address account => bool claimed) public hasClaimed;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Initialize contract with token and merkle root
    /// @param _token to be claimed (ERC20 compatible)
    /// @param _merkleRoot of the merkle tree
    /// Note: Sets owner to deployer
    constructor(ERC20 _token, bytes32 _merkleRoot) {
        token = _token;
        merkleRoot = _merkleRoot;

        _initializeOwner(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Claim tokens share as an account part of the merkle tree
    /// @param _recipient address of claimee
    /// @param _amount of tokens to claim
    /// @param _proof merkle proof to prove the 2 above parameters are part of the merkle tree
    /// Note: Uses `verifyCalldata` from `MerkleProofLib` as it is cheaper
    function claim(address _recipient, uint256 _amount, bytes32[] calldata _proof) external {
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
        token.transfer(_recipient, _amount);

        // Emit claim event
        emit Claimed(_recipient, _amount);
    }

    /// @notice Allows owner to rescue tokens
    function rescueTokens(uint256 _amount) external onlyOwner {
        // Transfer tokens to recipient (owner)
        token.transfer(msg.sender, _amount);
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
