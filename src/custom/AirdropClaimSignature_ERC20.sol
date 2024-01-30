// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Solady
import {ERC20} from "@solady/tokens/ERC20.sol";
import {ECDSA} from "@solady/utils/ECDSA.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @title AirdropClaimSignature_ERC20
/// @notice ERC20 claimable with signature
/// @dev Just an example - not audited
contract AirdropClaimSignature_ERC20 is Ownable {
    ERC20 public token;

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev The account has already claimed their tokens
    error AirdropClaimSignature_AlreadyClaimed();
    /// @dev The account has an invalid signature (malformed or nothing to claim)
    error AirdropClaimSignature_InvalidSignature();
    /// @dev The transfer of tokens failed
    error AirdropClaimSignature_TransferFailed();

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
    /// @dev Account that can sign messages to claim tokens
    address public immutable signer;

    /* ---------------------------------- STATE --------------------------------- */
    /// @dev Whether account has claimed tokens already
    mapping(address account => bool claimed) public hasClaimed;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @dev Initialize contract with tokens and merkle root
    /// @param _token to be claimed (ERC20 compatible)
    /// @param _signer of the claim messages
    /// Note: Sets owner to deployer
    constructor(ERC20 _token, address _signer) {
        token = _token;
        signer = _signer;

        _initializeOwner(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Claim tokens share with a valid signature
    /// @param _recipient address of the target account
    /// @param _amount of tokens to claim
    /// @param _signature of the claim message
    function claimERC20(address _recipient, uint256 _amount, bytes calldata _signature) external {
        // Throw if address has already claimed tokens
        if (hasClaimed[_recipient]) revert AirdropClaimSignature_AlreadyClaimed();

        // Recover signer from signature
        address recoveredSigner = ECDSA.recoverCalldata(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_recipient, _amount))), _signature
        );

        // Revert if recovered signer is not the signer
        if (recoveredSigner != signer) revert AirdropClaimSignature_InvalidSignature();

        // Mark account as claimed
        hasClaimed[_recipient] = true;
        // Transfer tokens to recipient
        bool success = token.transfer(_recipient, _amount);
        if (!success) revert AirdropClaimSignature_TransferFailed();

        // Emit claim event
        emit Claimed(_recipient, _amount);
    }
}
