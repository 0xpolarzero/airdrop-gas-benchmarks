// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Solady
import {ERC20} from "@solady/tokens/ERC20.sol";
import {ERC721} from "@solady/tokens/ERC721.sol";
import {ERC1155} from "@solady/tokens/ERC1155.sol";
import {ECDSA} from "@solady/utils/ECDSA.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @title AirdropClaimSignature
/// @notice ERC20, ERC721 & ERC1155 claimable with signature
/// @dev Just an example - not audited
contract AirdropClaimSignature is Ownable {
    ERC20 public erc20;
    ERC721 public erc721;
    ERC1155 public erc1155;

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

    /// @dev Emitted after a successful ERC20 claim
    /// @param recipient of the ERC20 tokens
    /// @param amount of tokens claimed
    event ClaimedERC20(address indexed recipient, uint256 amount);

    /// @dev Emitted after a successful ERC721 claim
    /// @param recipient of the ERC721 token
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
    /// @dev Account that can sign messages to claim tokens
    address public immutable signer;

    /* ---------------------------------- STATE --------------------------------- */
    /// @dev Whether account has claimed ERCx tokens already
    mapping(address account => bool claimed) public hasClaimed_erc20;
    mapping(address account => bool claimed) public hasClaimed_erc721;
    mapping(address account => bool claimed) public hasClaimed_erc1155;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @dev Initialize contract with tokens and merkle root
    /// @param _tokenERC20 to be claimed (ERC20 compatible)
    /// @param _tokenERC721 to be claimed (ERC721 compatible)
    /// @param _tokenERC1155 to be claimed (ERC1155 compatible)
    /// @param _signer of the claim messages
    /// Note: Sets owner to deployer
    constructor(ERC20 _tokenERC20, ERC721 _tokenERC721, ERC1155 _tokenERC1155, address _signer) {
        erc20 = _tokenERC20;
        erc721 = _tokenERC721;
        erc1155 = _tokenERC1155;
        signer = _signer;

        _initializeOwner(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Claim ERC20 tokens share with a valid signature
    /// @param _recipient address of the target account
    /// @param _amount of tokens to claim
    /// @param _signature of the claim message
    function claimERC20(address _recipient, uint256 _amount, bytes calldata _signature) external {
        // Throw if address has already claimed tokens
        if (hasClaimed_erc20[_recipient]) revert AirdropClaimSignature_AlreadyClaimed();

        // Recover signer from signature
        address recoveredSigner = ECDSA.recoverCalldata(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_recipient, _amount))), _signature
        );

        // Revert if recovered signer is not the signer
        if (recoveredSigner != signer) revert AirdropClaimSignature_InvalidSignature();

        // Mark account as claimed
        hasClaimed_erc20[_recipient] = true;
        // Transfer tokens to recipient
        erc20.transfer(_recipient, _amount);

        // Emit claim event
        emit ClaimedERC20(_recipient, _amount);
    }

    /// @dev Claim ERC721 token with a valid signature
    /// @param _recipient address of the target account
    /// @param _tokenId of the token to claim
    /// @param _signature of the claim message
    function claimERC721(address _recipient, uint256 _tokenId, bytes calldata _signature) external {
        // Throw if address has already claimed tokens
        if (hasClaimed_erc721[_recipient]) revert AirdropClaimSignature_AlreadyClaimed();

        // Recover signer from signature
        address recoveredSigner = ECDSA.recoverCalldata(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_recipient, _tokenId))), _signature
        );

        // Revert if recovered signer is not the signer
        if (recoveredSigner != signer) revert AirdropClaimSignature_InvalidSignature();

        // Mark account as claimed
        hasClaimed_erc721[_recipient] = true;
        // Transfer token to recipient
        erc721.transferFrom(address(this), _recipient, _tokenId);

        // Emit claim event
        emit ClaimedERC721(_recipient, _tokenId);
    }

    /// @dev Claim ERC1155 tokens share with a valid signature
    /// @param _recipient address of the target account
    /// @param _tokenId of the token to claim
    /// @param _amount of tokens to claim
    /// @param _signature of the claim message
    function claimERC1155(address _recipient, uint256 _tokenId, uint256 _amount, bytes calldata _signature) external {
        // Throw if address has already claimed tokens
        if (hasClaimed_erc1155[_recipient]) revert AirdropClaimSignature_AlreadyClaimed();

        // Recover signer from signature
        address recoveredSigner = ECDSA.recoverCalldata(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_recipient, _tokenId, _amount))), _signature
        );

        // Revert if recovered signer is not the signer
        if (recoveredSigner != signer) revert AirdropClaimSignature_InvalidSignature();

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
