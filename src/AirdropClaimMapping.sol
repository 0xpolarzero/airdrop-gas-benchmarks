// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Solady
import {ERC20} from "@solady/tokens/ERC20.sol";
import {ERC721} from "@solady/tokens/ERC721.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @title AirdropClaimMapping
/// @notice ERC20 & ERC721 claimable with mapping set by owner
/// Note: This is a highly inefficient approach to highlight common mistakes done with such claim-based airdrops.
/// This attempts to write the logic the way a beginner would find it intuitive.
/// Note: It allows only for a single ERC721 token to be claimed per address.
/// @dev Just an example - not audited
contract AirdropClaimMapping is Ownable {
    ERC20 public erc20;
    ERC721 public erc721;

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

    /* ---------------------------------- ERC20 --------------------------------- */

    /// @dev Emitted after a successful ERC20 airdrop (inscribed in mapping)
    /// @param recipient of the ERC20 tokens
    /// @param amount of tokens "airdropped"
    event AirdroppedERC20(address indexed recipient, uint256 amount);

    /// @dev Emitted after a successful ERC20 claim
    /// @param recipient of the ERC20 tokens
    /// @param amount of tokens claimed
    event ClaimedERC20(address indexed recipient, uint256 amount);

    /* ---------------------------------- ERC721 --------------------------------- */

    /// @dev Emitted after a successful ERC721 airdrop (inscribed in mapping)
    /// @param recipient of the ERC721 tokens
    /// @param tokenId of the ERC721 token "airdropped"
    event AirdroppedERC721(address indexed recipient, uint256 tokenId);

    /// @dev Emitted after a successful ERC721 claim
    /// @param recipient of the ERC721 tokens
    /// @param tokenId of the ERC721 token claimed
    event ClaimedERC721(address indexed recipient, uint256 tokenId);

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /* ---------------------------------- ERC20 --------------------------------- */

    /// @dev Mapping of ERC20 tokens available for claim for each account
    mapping(address account => uint256 amount) public balances_erc20;

    /* ---------------------------------- ERC721 --------------------------------- */

    /// @dev Mapping of ERC721 token available for claim for each account
    mapping(address account => uint256 tokenId) public balances_erc721;
    /// @dev Mapping of whether an account has claimed their ERC721 token
    /// Note: Necessary only because an account might have tokenID 0 available for claim
    /// which is the default value
    mapping(address account => bool canClaim) public allowed_erc721;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @dev Initialize contract with token
    /// @param _tokenERC20 to be claimed (ERC20 compatible)
    /// @param _tokenERC721 to be claimed (ERC721 compatible)
    /// Note: Sets owner to deployer
    constructor(ERC20 _tokenERC20, ERC721 _tokenERC721) {
        erc20 = _tokenERC20;
        erc721 = _tokenERC721;

        _initializeOwner(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Deposit ERC20 tokens to be claimed and write available amounts for each account to mapping
    /// @param _recipients of the ERC20 tokens
    /// @param _amounts of tokens to be claimed
    /// Note: There are many flaws with this approach, such as:
    /// - Writing every single recipient/amount pair to storage
    /// - Emitting an event for each operation
    function airdropERC20(address[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {
        if (_recipients.length != _amounts.length) revert AirdropClaimMapping_MismatchedArrays();

        uint256 total;
        for (uint256 i = 0; i < _recipients.length; i++) {
            balances_erc20[_recipients[i]] += _amounts[i];
            total += _amounts[i];

            emit AirdroppedERC20(_recipients[i], _amounts[i]);
        }

        if (!erc20.transferFrom(msg.sender, address(this), total)) revert AirdropClaimMapping_TransferFailed();
    }

    /// @dev Deposit ERC721 tokens to be claimed and write available amounts for each account to mapping
    /// @param _recipients of the ERC721 tokens
    /// @param _tokenIds of tokens to be claimed
    /// Note: There are many flaws with this approach, such as:
    /// - Writing every single recipient/tokenId pair to storage
    /// - Using two mappings to track the associated id AND whether it can be claimed, due to the fact
    /// that the ERC721 token might have the id 0, which is the default value for the mapping
    /// - Emitting an event for each operation
    /// - Using an ERC721 token that does not support batch transfers
    function airdropERC721(address[] calldata _recipients, uint256[] calldata _tokenIds) external onlyOwner {
        if (_recipients.length != _tokenIds.length) revert AirdropClaimMapping_MismatchedArrays();

        for (uint256 i = 0; i < _recipients.length; i++) {
            balances_erc721[_recipients[i]] = _tokenIds[i];
            allowed_erc721[_recipients[i]] = true;
            erc721.transferFrom(msg.sender, address(this), _tokenIds[i]);

            emit AirdroppedERC721(_recipients[i], _tokenIds[i]);
        }
    }

    /// @dev Claim ERC20 tokens share as an account part of the mapping
    function claimERC20() external {
        uint256 balance = balances_erc20[msg.sender];
        if (balance == 0) revert AirdropClaimMapping_NothingToClaim();

        balances_erc20[msg.sender] = 0;
        if (!erc20.transfer(msg.sender, balance)) revert AirdropClaimMapping_TransferFailed();

        emit ClaimedERC20(msg.sender, balance);
    }

    /// @dev Claim ERC721 tokens share as an account part of the mapping
    function claimERC721() external {
        uint256 tokenId = balances_erc721[msg.sender];
        if (!allowed_erc721[msg.sender]) revert AirdropClaimMapping_NothingToClaim();

        allowed_erc721[msg.sender] = false;
        erc721.transferFrom(address(this), msg.sender, tokenId);

        emit ClaimedERC721(msg.sender, tokenId);
    }
}
