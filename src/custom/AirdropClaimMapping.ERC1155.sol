// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Solady
import {ERC1155} from "@solady/tokens/ERC1155.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @title AirdropClaimMappingERC1155
/// @notice ERC1155 claimable with mapping set by owner
/// Note: This is a highly inefficient approach to highlight common mistakes done with such claim-based airdrops.
/// Especially, to show how much these mistakes can cost in terms of gas.
/// This attempts to write the logic the way a beginner would find it intuitive.
/// Note: It allows only for a single ERC1155 tokenId to be claimed per address.
/// @dev Just an example - not audited
contract AirdropClaimMappingERC1155 is Ownable {
    ERC1155 public token;

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev The length of the recipients, amounts and tokenIds arrays do not match
    error AirdropClaimMapping_MismatchedArrays();
    /// @dev The transfer of tokens failed
    error AirdropClaimMapping_TransferFailed();
    /// @dev The account has nothing to claim
    error AirdropClaimMapping_NothingToClaim();

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Emitted after a successful airdrop (inscribed in mapping)
    /// @param recipient of the tokens
    /// @param tokenId of the token
    /// @param amount of tokens at this id
    event Airdropped(address indexed recipient, uint256 tokenId, uint256 amount);

    /// @dev Emitted after a successful claim
    /// @param recipient of the tokens
    /// @param tokenId of the token
    /// @param amount of tokens claimed at this id
    event Claimed(address indexed recipient, uint256 tokenId, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev Mapping of ERC1155 tokens available for claim for each account
    mapping(address account => mapping(uint256 tokenId => uint256 amount)) public balances;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @dev Initialize contract with token
    /// @param _token to be claimed (ERC1155 compatible)
    /// Note: Sets owner to deployer
    constructor(ERC1155 _token) {
        token = _token;
        _initializeOwner(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Deposit ERC1155 tokens to be claimed and write available amounts for each account to mapping
    /// @param _recipients of the ERC1155 tokens
    /// @param _tokenIds of tokens to be claimed
    /// @param _amounts of tokens to be claimed
    /// Note: There are many flaws with this approach, such as:
    /// - Writing every single pair to storage
    /// - Emitting an event for each operation
    /// - Allowing only a single id to be claimed per account
    function airdropERC1155(address[] calldata _recipients, uint256[] calldata _tokenIds, uint256[] calldata _amounts)
        external
        onlyOwner
    {
        if (_recipients.length != _tokenIds.length || _recipients.length != _amounts.length) {
            revert AirdropClaimMapping_MismatchedArrays();
        }

        for (uint256 i = 0; i < _recipients.length; i++) {
            balances[_recipients[i]][_tokenIds[i]] = _amounts[i];
            emit Airdropped(_recipients[i], _tokenIds[i], _amounts[i]);
        }

        // This will be called repeatedly for each recipient/tokenId pair...
        token.safeBatchTransferFrom(msg.sender, address(this), _tokenIds, _amounts, "");
    }

    /// @dev Claim ERC1155 tokens share as an account part of the mapping
    /// @param _tokenId of the ERC1155 token to be claimed
    function claimERC1155(uint256 _tokenId) external {
        uint256 balance = balances[msg.sender][_tokenId];
        if (balance == 0) revert AirdropClaimMapping_NothingToClaim();

        balances[msg.sender][_tokenId] = 0;
        token.safeTransferFrom(address(this), msg.sender, _tokenId, balance, "");

        emit Claimed(msg.sender, _tokenId, balance);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   ERC1155                                  */
    /* -------------------------------------------------------------------------- */

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
