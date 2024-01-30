// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Solady
import {ERC1155} from "@solady/tokens/ERC1155.sol";
import {ECDSA} from "@solady/utils/ECDSA.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @title AirdropClaimSignature_ERC1155
/// @notice ERC1155 claimable with signature
/// @dev Just an example - not audited
contract AirdropClaimSignature_ERC1155 is Ownable {
    ERC1155 public token;

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
    /// @param recipient of the ERC1155 tokens
    /// @param tokenId of the ERC1155 token claimed
    /// @param amount of tokens claimed
    event Claimed(address indexed recipient, uint256 tokenId, uint256 amount);

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
    /// @param _token to be claimed (ERC1155 compatible)
    /// @param _signer of the claim messages
    /// Note: Sets owner to deployer
    constructor(ERC1155 _token, address _signer) {
        token = _token;
        signer = _signer;

        _initializeOwner(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Claim tokens share with a valid signature
    /// @param _recipient address of the target account
    /// @param _tokenId of the token to claim
    /// @param _amount of tokens to claim
    /// @param _signature of the claim message
    function claimERC1155(address _recipient, uint256 _tokenId, uint256 _amount, bytes calldata _signature) external {
        // Throw if address has already claimed tokens
        if (hasClaimed[_recipient]) revert AirdropClaimSignature_AlreadyClaimed();

        // Recover signer from signature
        address recoveredSigner = ECDSA.recoverCalldata(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_recipient, _tokenId, _amount))), _signature
        );

        // Revert if recovered signer is not the signer
        if (recoveredSigner != signer) revert AirdropClaimSignature_InvalidSignature();

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
