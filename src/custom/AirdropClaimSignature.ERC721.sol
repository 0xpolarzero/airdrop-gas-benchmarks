// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Solady
import {ERC721} from "@solady/tokens/ERC721.sol";
import {ECDSA} from "@solady/utils/ECDSA.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @title AirdropClaimSignatureERC721
/// @notice ERC721 claimable with signature
/// @dev Just an example - not audited
contract AirdropClaimSignatureERC721 is Ownable {
    ERC721 public token;

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev The account has already claimed their tokens
    error AirdropClaimSignature_AlreadyClaimed();
    /// @dev The account has an invalid signature (malformed or nothing to claim)
    error AirdropClaimSignature_InvalidSignature();

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Emitted after a successful claim
    /// @param recipient of the ERC721 token
    /// @param tokenId of the ERC721 token claimed
    event Claimed(address indexed recipient, uint256 tokenId);

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    /* -------------------------------- IMMUTABLE ------------------------------- */
    /// @dev Account that can sign messages to claim tokens
    address public immutable signer;

    /* ---------------------------------- STATE --------------------------------- */
    /// @dev Whether account has claimed tokens already
    mapping(address account => bool claimed) public hasClaimed;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @dev Initialize contract with tokens and merkle root
    /// @param _token to be claimed (ERC721 compatible)
    /// @param _signer of the claim messages
    /// Note: Sets owner to deployer
    constructor(ERC721 _token, address _signer) {
        token = _token;
        signer = _signer;

        _initializeOwner(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Claim NFT with a valid signature
    /// @param _recipient address of the target account
    /// @param _tokenId of the token to claim
    /// @param _signature of the claim message
    function claimERC721(address _recipient, uint256 _tokenId, bytes calldata _signature) external {
        // Throw if address has already claimed tokens
        if (hasClaimed[_recipient]) revert AirdropClaimSignature_AlreadyClaimed();

        // Recover signer from signature
        address recoveredSigner = ECDSA.recoverCalldata(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_recipient, _tokenId))), _signature
        );

        // Revert if recovered signer is not the signer
        if (recoveredSigner != signer) revert AirdropClaimSignature_InvalidSignature();

        // Mark account as claimed
        hasClaimed[_recipient] = true;
        // Transfer token to recipient
        token.transferFrom(address(this), _recipient, _tokenId);

        // Emit claim event
        emit Claimed(_recipient, _tokenId);
    }
}
