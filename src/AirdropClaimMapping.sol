// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Solady
import {ERC20} from "@solady/tokens/ERC20.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @title AirdropClaimMapping
/// @notice ERC20 claimable with mapping set by owner
/// Note: This is a highly inefficient approach to highlight common mistakes done with such claim-based airdrops.
/// @dev Just an example - not audited
contract AirdropClaimMapping is Ownable {
    ERC20 public token;

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
    /// @param recipient of the ERC20 tokens
    /// @param amount of tokens "airdropped"
    event Airdropped(address indexed recipient, uint256 amount);

    /// @dev Emitted after a successful claim
    /// @param recipient of the ERC20 tokens
    /// @param amount of tokens claimed
    event Claimed(address indexed recipient, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev Mapping of ERC20 tokens available for claim for each account
    mapping(address account => uint256 amount) public balances;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @dev Initialize contract with token
    /// @param _token to be claimed (ERC20 compatible)
    /// Note: Sets owner to deployer
    constructor(ERC20 _token) {
        token = _token;

        _initializeOwner(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Deposit tokens to be claimed and write available amounts for each account to mapping
    /// @param _recipients of the ERC20 tokens
    /// @param _amounts of tokens to be claimed
    /// Note: There are many flaws with this approach, such as:
    /// - Writing every single recipient/amount pair to storage
    /// - Emitting an event for each operation
    function airdrop(address[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {
        if (_recipients.length != _amounts.length) revert AirdropClaimMapping_MismatchedArrays();

        uint256 total;
        for (uint256 i = 0; i < _recipients.length; i++) {
            balances[_recipients[i]] += _amounts[i];
            total += _amounts[i];

            emit Airdropped(_recipients[i], _amounts[i]);
        }

        if (!token.transferFrom(msg.sender, address(this), total)) revert AirdropClaimMapping_TransferFailed();
    }

    /// @dev Claim tokens share as an account part of the mapping
    function claim() external {
        uint256 balance = balances[msg.sender];
        if (balance == 0) revert AirdropClaimMapping_NothingToClaim();

        balances[msg.sender] = 0;
        if (!token.transfer(msg.sender, balance)) revert AirdropClaimMapping_TransferFailed();

        emit Claimed(msg.sender, balance);
    }

    /// @dev Allows owner to rescue tokens
    /// @param _amount of tokens to rescue
    function rescueTokens(uint256 _amount) external onlyOwner {
        token.transfer(msg.sender, _amount);
    }
}
