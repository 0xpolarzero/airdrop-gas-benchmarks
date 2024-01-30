// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Solady
import {ERC721} from "@solady/tokens/ERC721.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @title AirdropClaimMapping_ERC721
/// @notice ERC721 claimable with mapping set by owner
/// Note: This is a highly inefficient approach to highlight common mistakes done with such claim-based airdrops.
/// Especially, to show how much these mistakes can cost in terms of gas.
/// This attempts to write the logic the way a beginner would find it intuitive.
/// Note: It allows only for a single ERC721 token to be claimed per address.
/// @dev Just an example - not audited
contract AirdropClaimMapping_ERC721 is Ownable {
    ERC721 public token;

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev The length of the recipients and amounts arrays do not match
    error AirdropClaimMapping_MismatchedArrays();
    /// @dev The transfer of tokens failed
    error AirdropClaimMapping_TransferFailed();
    /// @dev The account has nothing to claim
    error AirdropClaimMapping_NothingToClaim();

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Emitted after a successful airdrop (inscribed in mapping)
    /// @param recipient of the ERC721 tokens
    /// @param tokenId of the ERC721 token "airdropped"
    event Airdropped(address indexed recipient, uint256 tokenId);

    /// @dev Emitted after a successful  claim
    /// @param recipient of the ERC721 tokens
    /// @param tokenId of the ERC721 token claimed
    event Claimed(address indexed recipient, uint256 tokenId);

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev Mapping of NFT available for claim for each account
    mapping(address account => uint256 tokenId) public balances;
    /// @dev Mapping of whether an account has claimed their NFT
    /// Note: Necessary only because an account might have tokenID 0 available for claim
    /// which is the default value
    mapping(address account => bool canClaim) public allowed;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @dev Initialize contract with token
    /// @param _token to be claimed (ERC721 compatible)
    /// Note: Sets owner to deployer
    constructor(ERC721 _token) {
        token = _token;
        _initializeOwner(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Deposit tokens to be claimed and write available amounts for each account to mapping
    /// @param _recipients of the NFTs
    /// @param _tokenIds of NFT to be claimed
    /// Note: There are many flaws with this approach, such as:
    /// - Writing every single recipient/tokenId pair to storage
    /// - Using two mappings to track the associated id AND whether it can be claimed, due to the fact
    /// that the ERC721 token might have the id 0, which is the default value for the mapping
    /// - Emitting an event for each operation
    /// - Using an ERC721 token that does not support batch transfers
    function airdropERC721(address[] calldata _recipients, uint256[] calldata _tokenIds) external onlyOwner {
        if (_recipients.length != _tokenIds.length) revert AirdropClaimMapping_MismatchedArrays();

        for (uint256 i = 0; i < _recipients.length; i++) {
            balances[_recipients[i]] = _tokenIds[i];
            allowed[_recipients[i]] = true;
            token.transferFrom(msg.sender, address(this), _tokenIds[i]);

            emit Airdropped(_recipients[i], _tokenIds[i]);
        }
    }

    /// @dev Claim ERC721 tokens share as an account part of the mapping
    function claimERC721() external {
        uint256 tokenId = balances[msg.sender];
        if (!allowed[msg.sender]) revert AirdropClaimMapping_NothingToClaim();

        allowed[msg.sender] = false;
        token.transferFrom(address(this), msg.sender, tokenId);

        emit Claimed(msg.sender, tokenId);
    }
}
