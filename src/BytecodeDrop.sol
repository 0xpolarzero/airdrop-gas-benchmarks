// From: @0xjustadev
//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract BytecodeDrop {
    constructor() {
        assembly {
            mstore(0x00, 0x59351559341117600D57601A565B5959FD5B6000526004601CFD5B593560E01C)
            mstore(0x20, 0x6382947ABE14602D575B3434FD5B602435600401604435600401808203813583)
            mstore(0x40, 0x3581036055576004357F23b872dd000000000000000000000000000000000000)
            mstore(0x60, 0x0000000000000000000034523360045230602452606435604452343460643434)
            mstore(0x80, 0x855AF1156055577Fa9059cbb0000000000000000000000000000000000000000)
            mstore(0xA0, 0x000000000000000034528160051B60200185018560015B906020018083031560)
            mstore(0xC0, 0xDC5790813560045285820335602452343460443434885AF11660B6565B156055)
            mstore(0xE0, 0x573434F300000000000000000000000000000000000000000000000000000000)
            return(0x00, 0xE4)
        }
    }

    /**
     * @notice Airdrop ERC20 tokens to a list of addresses
     * @param _token The address of the ERC20 contract
     * @param _addresses The addresses to airdrop to
     * @param _amounts The amounts to airdrop
     * @param _totalAmount The total amount to airdrop
     */
    function airdropERC20(
        address _token,
        address[] calldata _addresses,
        uint256[] calldata _amounts,
        uint256 _totalAmount
    ) external {}
}
