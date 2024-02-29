# Gas consumption benchmarks for popular airdrop patterns

This repository contains a series of tests to measure gas usage for popular airdrop patterns with various token standards and airdrop mechanisms. Including:

- native currency (ETH);
- ERC20;
- ERC721;
- ERC1155.

The custom mapping-based contracts ([`AirdropClaimMappingERC{20/721/1155}`](./src/custom/AirdropClaimMapping.ERC20.sol)), and to some extent [`AirdropClaimMerkleERC{20/721/1155}`](./src/custom/AirdropClaimMerkle.ERC20.sol) and [`AirdropClaimSignatureERC{20/721/1155}`](./src/custom/AirdropClaimSignature.ERC20.sol) as well, are purposely written poorly to fit common assumptions and patterns found in the wild.

## Table of contents

- [Overview](#overview)
  - [Airdrop mechanisms (custom contracts)](#airdrop-mechanisms-custom-contracts)
  - [Airdrop solutions (including already deployed contracts)](#airdrop-solutions-including-already-deployed-contracts)
- [Results](#results)
  - [ERC20 (push-based)](#erc20-direct-airdrop)
  - [ERC20 (claim-based)](#erc20-claim-based-airdrop)
  - [ERC721 (push-based)](#erc721-direct-airdrop)
  - [ERC721 (claim-based)](#erc721-claim-based-airdrop)
  - [ERC1155 (push-based)](#erc1155-direct-airdrop)
  - [ERC1155 (claim-based)](#erc1155-claim-based-airdrop)
  - [ETH (push-based)](#eth-direct-airdrop)
- [How to run](#how-to-run)
  - [Setup](#setup)
  - [Usage](#usage)

## Overview

### Airdrop mechanisms (custom contracts):

| Type                                              | Tokens                 | Contract                                                                                                                                                                                                                                       |
| ------------------------------------------------- | ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Claimable airdrop (data inscribed into a mapping) | ERC20, ERC721, ERC1155 | [`AirdropClaimMappingERC20`](./src/custom/AirdropClaimMapping.ERC20.sol), [`AirdropClaimMappingERC721`](./src/custom/AirdropClaimMapping.ERC721.sol), [`AirdropClaimMappingERC1155`](./src/custom/AirdropClaimMapping.ERC1155.sol)             |
| Claimable airdrop (merkle proof)                  | ERC20, ERC721, ERC1155 | [`AirdropClaimMerkleERC20`](./src/custom/AirdropClaimMerkle.ERC20.sol), [`AirdropClaimMerkleERC721`](./src/custom/AirdropClaimMerkle.ERC721.sol), [`AirdropClaimMerkleERC1155`](./src/custom/AirdropClaimMerkle.ERC1155.sol)                   |
| Claimable airdrop (signature)                     | ERC20, ERC721, ERC1155 | [`AirdropClaimSignatureERC20`](./src/custom/AirdropClaimSignature.ERC20.sol), [`AirdropClaimSignatureERC721`](./src/custom/AirdropClaimSignature.ERC721.sol), [`AirdropClaimSignatureERC1155`](./src/custom/AirdropClaimSignature.ERC1155.sol) |
| Airdrop (bytecode contract)                       | ERC20                  | [`BytecodeDrop`](./src/BytecodeDrop.sol)                                                                                                                                                                                                       |

### Airdrop solutions (including already deployed contracts):

| Type                                              | Tokens                 | Contract                                                                                                                                                                                                            | Website/source code                                  |
| ------------------------------------------------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| GasliteDrop (airdrop)                             | ETH, ERC20, ERC721     | [`GasliteDrop`](./src/GasliteDrop.sol)                                                                                                                                                                              | [drop.gaslite.org](https://drop.gaslite.org/)        |
| GasliteDrop1155 (airdrop)                         | ERC1155                | [`GasliteDrop1155`](./src/GasliteDrop1155.sol)                                                                                                                                                                      | [drop.gaslite.org](https://drop.gaslite.org/)        |
| GasliteMerkleDN (claimable airdrop, merkle proof) | ETH                    | [`GasliteMerkleDN`](./src/GasliteMerkleDN.sol)                                                                                                                                                                      | [gaslite.org](https://gaslite.org/)                  |
| GasliteMerkleDT (claimable airdrop, merkle proof) | ERC20                  | [`GasliteMerkleDT`](./src/GasliteMerkleDT.sol)                                                                                                                                                                      | [gaslite.org](https://gaslite.org/)                  |
| Disperse.app (airdrop)                            | ETH, ERC20             | [`Disperse`](./src/Disperse.sol)                                                                                                                                                                                    | [disperse.app](https://disperse.app/)                |
| wentokens (airdrop)                               | ETH, ERC20             | [`Airdrop`](./src/Wentokens.sol)                                                                                                                                                                                    | [www.wentokens.xyz](https://www.wentokens.xyz/)      |
| Thirdweb (airdrop)                                | ERC20, ERC721, ERC1155 | [`AirdropERC20`](./src/thirdweb/AirdropERC20.sol), [`AirdropERC721`](./src/thirdweb/AirdropERC721.sol), [`AirdropERC1155`](./src/thirdweb/AirdropERC1155.sol)                                                       | [thirdweb.com](https://thirdweb.com/explore/airdrop) |
| Thirdweb (claimable airdrop, merkle proof)        | ERC20, ERC721, ERC1155 | [`AirdropERC20Claimable`](./src/thirdweb/AirdropERC20Claimable.sol), [`AirdropERC721Claimable`](./src/thirdweb/AirdropERC721Claimable.sol), [`AirdropERC1155Claimable`](./src/thirdweb/AirdropERC1155Claimable.sol) | [thirdweb.com](https://thirdweb.com/explore/airdrop) |

---

This Readme is an attempt to showcase the results in an organized and sorted manner.

> [!NOTE]
> The benchmarks do not include the gas consumption for [the bytecode contract](./src/BytecodeDrop.sol), as [a current limitation with Forge](https://github.com/foundry-rs/foundry/issues/6129); this should actually be the most efficient way for airdropping ERC20 tokens.

## Results

The tables below are based on gas benchmarks with the following parameters:

- 1,000 different random recipients;
- random amounts between 1e10 and 1e19 (10 \* 18 decimals), except for ERC721 (1 token per recipient);
- some amounts are repeated randomly to better simulate real world scenarios ([see here](./test/Benchmarks.base.sol#L260));
- randomness is generated with [Solady LibPRNG](https://github.com/Vectorized/solady/blob/main/src/utils/LibPRNG.sol), taking advantage of random calldata generated with fuzzing (see the unnamed uint256 parameter in each test function);
- the gas consumption is measured [with Forge](https://book.getfoundry.sh/forge/gas-reports?highlight=gas-report#gas-reports);
- Thirdweb contracts are supposed to be deployed as a proxy pointing to the actual implementation, so the cost of deploying the implementation is not included in the report.

See [the full report](./gas-report.txt) for more details or [generate it yourself](#how-to-run).

### Notes

For **claim-based airdrops**, multiple measurements are taken into account:

1. deployment/initilization (e.g. Thirdweb contracts require only a proxy to be deployed, but the proxy needs to be initialized with the airdrop data, which can be quite expensive);
2. deposit/airdrop (e.g. depositing tokens, writing the airdrop data to the contract);
3. claim.

Steps 1 and 2 are aggregated into `Gas deployment`, with the details for each amount in such way: `total (deployment/initialization + deposit/airdrop)`.

For **push-based airdrops**, the gas cost of deploying and initializing the contract is ignored, as all solutions, excluding Thirdweb, are already deployed and available for use (direct call to the airdrop function).

### ERC20 (push-based)

| Rank | Contract                                                       | Gas (1,000 recipients) | Difference from #1             |
| ---- | -------------------------------------------------------------- | ---------------------- | ------------------------------ |
| 1    | [`GasliteDrop`](./src//GasliteDrop.sol#L86)                    | 25,542,088 <!-- g -->  | 0                              |
| 2    | Wentokens [`Airdrop`](./src/Wentokens.sol#L77)                 | 25,586,923 <!-- g -->  | +44,835 (+0.18%) <!-- g -->    |
| 3    | [`Disperse`](./src/Disperse.sol#L20) (`disperseToken`)         | 26,342,497 <!-- g -->  | +800,409 (+3.13%) <!-- g -->   |
| 4    | [`Disperse`](./src//Disperse.sol#L31) (`disperseTokenSimple`)  | 26,852,552 <!-- g -->  | +1,310,464 (+5.13%) <!-- g --> |
| 5    | Thirdweb [`AirdropERC20`](./src/thirdweb/AirdropERC20.sol#L96) | 26,925,358 <!-- g -->  | +1,383,270 (+5.41%) <!-- g --> |

### ERC20 (claim-based)

| Rank | Contract                                                                     | Gas deployment (1,000 recipients)            | Difference from #1                  | Gas claim (1 recipient) | Difference from #1           |
| ---- | ---------------------------------------------------------------------------- | -------------------------------------------- | ----------------------------------- | ----------------------- | ---------------------------- |
| 1    | [`AirdropClaimSignature`](./src/custom/AirdropClaimSignature.ERC20.sol)      | 496,127 (496,127 + 0) <!-- g -->             | 0                                   | 85,766 <!-- g -->       | 0                            |
| 2    | [`AirdropClaimMerkle`](./src/custom/AirdropClaimMerkle.ERC20.sol)            | 464,492 (464,492 + 0) <!-- g -->             | -31,635 (-6.81%) <!-- g -->         | 87,547 <!-- g -->       | +1,781 (+2.03%) <!-- g -->   |
| 3    | [`GasliteMerkleDT`](./src/GasliteMerkleDT.sol)                               | 647,007 (601,488 + 45,519) <!-- g -->        | +150,880 (+30.41%) <!-- g -->       | 88,613 <!-- g -->       | +2,847 (+3.32%) <!-- g -->   |
| 4    | Thirdweb [`AirdropERC20Claimable`](./src/thirdweb/AirdropERC20Claimable.sol) | 207,525 (66,769 + 140,756) <!-- g -->        | -288,602 (-58.17%) <!-- g -->       | 90,267 <!-- g -->       | +4,501 (+5.25%) <!-- g -->   |
| 5    | [`AirdropClaimMapping`](./src/custom/AirdropClaimMapping.ERC20.sol)          | 25,666,389 (538,776 + 25,127,613) <!-- g --> | +25,170,262 (+5,073.25%) <!-- g --> | 57,631 <!-- g -->       | -28,135 (-32.80%) <!-- g --> |

This comparison is opinionated. Some arguments to support it:

- The difference in deployment cost is too significant for `AirdropClaimMapping` to be considered a viable solution. Although, in pure gas terms, for 1,000 recipients, it's still cheaper than the Thirdweb and signature-based solutions, i.e. it will spend less gas in total.
- Although the deployment for Thirdweb's `AirdropERC20Claimable` is half the cost of `AirdropClaimMerkle` or `AirdropClaimSignature`, the increase in gas for claiming is too significant to have it ranked higher. I believe that the deployer paying ~400-500,000 gas instead of ~200,000 cannot justify each single claimer having to pay ~90,000 gas instead of ~86,000.

In any case, these are only benchmarks, with a ranking provided for convenience.

It's also worth noting that the top 1 and 2 custom contracts are really just mock implementations. Although they do allow claiming on behalf of another account, they lack some checks and utility functions (e.g. pausing the claim)—the position of these contracts in the ranking is not a recommendation to use them, but rather based on the gas consumption.

### ERC721 (push-based)

| Rank | Contract                                                         | Gas (1,000 recipients) | Difference from #1             |
| ---- | ---------------------------------------------------------------- | ---------------------- | ------------------------------ |
| 1    | [`GasliteDrop`](./src/GasliteDrop.sol#L46)                       | 33,103,232 <!-- g -->  | 0                              |
| 2    | Thirdweb [`AirdropERC721`](./src/thirdweb/AirdropERC721.sol#L93) | 35,844,727 <!-- g -->  | +2,741,495 (+8.28%) <!-- g --> |

### ERC721 (claim-based)

| Rank | Contract                                                                       | Gas deployment (1,000 recipients)            | Difference from #1                  | Gas claim (1 recipient) | Difference from #1                 |
| ---- | ------------------------------------------------------------------------------ | -------------------------------------------- | ----------------------------------- | ----------------------- | ---------------------------------- |
| 1    | [`AirdropClaimSignature`](./src/custom/AirdropClaimSignature.ERC721.sol)       | 479,098 (479,098 + 0) <!-- g -->             | 0                                   | 93,072 <!-- g -->       | 0                                  |
| 2    | [`AirdropClaimMerkle`](./src/custom/AirdropClaimMerkle.ERC721.sol)             | 447,613 (447,613 + 0) <!-- g -->             | -31,485 (-6.57%) <!-- g -->         | 94,953 <!-- g -->       | +1,881 (+2.02%) <!-- g -->         |
| 3    | [`AirdropClaimMapping`](./src/custom/AirdropClaimMapping.ERC721.sol)           | 36,472,337 (520,397 + 35,951,940) <!-- g --> | +35,993,239 (+7,512.71%) <!-- g --> | 65,162 <!-- g -->       | -27,910 (-29.99%) <!-- g -->       |
| 4    | Thirdweb [`AirdropERC721Claimable`](./src/thirdweb/AirdropERC721Claimable.sol) | 22,452,426 (66,769 + 22,385,657) <!-- g -->  | +21,973,328 (+4,586.40%) <!-- g --> | 2,257,594 <!-- g -->    | +2,164,522 (+2,325.64%) <!-- g --> |

It really hurts to not put `AirdropClaimMapping` in the last place, but Thirdweb's `AirdropERC721Claimable` really is too much with both the ~30M gas deployment and the ~218k gas claims. With 1,000 recipients, it is more than 219M in gas just for users to claim their tokens...

Also, `AirdropERC721Claimable` does not allow for airdroping specific tokens to specific accounts, it will just allow to claim `n` amount of tokens, and read the tokenIds array in ascending order. So it basically looks like a minting function.

### ERC1155 (push-based)

> [!NOTE]
> The following is measured with Hardhat, due to an issue with Forge gas report.
>
> See [hardhat](./hardhat/) for more details.

| Rank | Contract                                                           | Gas (1,000 recipients) | Difference from #1                |
| ---- | ------------------------------------------------------------------ | ---------------------- | --------------------------------- |
| 1    | [`GasliteDrop1155`](./src/GasliteDrop1155.sol#L64)                 | 12,755,797 <!-- g -->  | 0                                 |
| 2    | Thirdweb [`AirdropERC1155`](./src/thirdweb/AirdropERC1155.sol#L93) | 30,320,907 <!-- g -->  | +17,565,110 (+137.70%) <!-- g --> |

It's worth noting that `GasliteDrop1155` takes advantage of multiple recipients with same amount by packing them into a single struct. Which much better simulates real world scenarios (e.g. users being rewarded the same amounts for the same token IDs after accomplishing a similar task). See:

```solidity
struct AirdropTokenAmount {
    uint256 amount;
    address[] recipients;
}
```

In these tests, there are ~14% of recipients aggregated with the same amount. As the proportion of recipients with the same amount increases, the gap in gas consumption between `GasliteDrop1155` and Thirdweb's `AirdropERC1155` contract will increase as well.

### ERC1155 (claim-based)

| Rank | Contract                                                                         | Gas deployment (1,000 recipients)            | Difference from #1                  | Gas claim (1 recipient) | Difference from #1           |
| ---- | -------------------------------------------------------------------------------- | -------------------------------------------- | ----------------------------------- | ----------------------- | ---------------------------- |
| 1    | [`AirdropClaimSignature`](./src/custom/AirdropClaimSignature.ERC1155.sol)        | 609,717 (609717 + 0) <!-- g -->              | 0                                   | 87,405 <!-- g -->       | 0                            |
| 2    | [`AirdropClaimMerkle`](./src/custom/AirdropClaimMerkle.ERC1155.sol)              | 577,332 (577,332 + 0) <!-- g -->             | -32,385 (-5.31%) <!-- g -->         | 89,236 <!-- g -->       | +1,831 (+2.10%) <!-- g -->   |
| 3    | Thirdweb [`AirdropERC1155Claimable`](./src/thirdweb/AirdropERC1155Claimable.sol) | 1,556,310 (66,769 + 1,489,541) <!-- g -->    | +946,593 (+155.25%) <!-- g -->      | 88,990 <!-- g -->       | +1,585 (+1.81%) <!-- g -->   |
| 4    | [`AirdropClaimMapping`](./src/custom/AirdropClaimMapping.ERC1155.sol)            | 27,929,999 (697,536 + 27,232,463) <!-- g --> | +27,320,282 (+4,480.81%) <!-- g --> | 59,402 <!-- g -->       | -28,003 (-32.03%) <!-- g --> |

These contracts allow only for claiming a single token ID per recipient, to fit the Thirdweb pattern.

### ETH (push-based)

| Rank | Contract                                       | Gas (1,000 recipients) | Difference from #1           |
| ---- | ---------------------------------------------- | ---------------------- | ---------------------------- |
| 1    | [`GasliteDrop`](./src/GasliteDrop.sol#L137)    | 9,996,017 <!-- g -->   | 0                            |
| 2    | Wentokens [`Airdrop`](./src/Wentokens.sol#L32) | 10,050,255 <!-- g -->  | +54,238 (+0.54%) <!-- g -->  |
| 3    | [`Disperse`](./src/Disperse.sol#L10)           | 10,314,834 <!-- g -->  | +318,817 (+3.19%) <!-- g --> |

> [!NOTE]
> There tests use already initialized accounts—that is, accounts that were sent 1 wei prior to the measurement—to better simulate real world scenarios. This helps to avoid the cost of both the cold account access (2,500 gas) and the initialization surcharges (25,000 gas).
> [See here for reference](https://github.com/foundry-rs/foundry/issues/7047#issuecomment-1935424409)

### ETH (claim-based)

| Rank | Contract                                       | Gas deployment (1,000 recipients)     | Difference from #1 | Gas claim (1 recipient) | Difference from #1 |
| ---- | ---------------------------------------------- | ------------------------------------- | ------------------ | ----------------------- | ------------------ |
| 1    | [`GasliteMerkleDN`](./src/GasliteMerkleDN.sol) | 536,646 (491,127 + 45,519) <!-- g --> | 0                  | 87,177 <!-- g -->       | 0                  |

## How to run

### Setup

1. Clone the repository and navigate to the root directory

```sh
git clone git@github.com:0xpolarzero/airdrop-gas-benchmarks.git
cd airdrop-gas-benchmarks
```

2. [Install Foundry](https://book.getfoundry.sh/getting-started/installation)

3. Customize the amount of recipients [here](./test/Benchmarks.base.sol#L45) and the amount of ERC1155 tokens ids to distribute [here](./test/Benchmarks.base.sol#L47)

### Usage

1. Run all tests with gas snapshots

```sh
# Output to stdout
forge test --gas-report
# Output to file
forge test --gas-report > gas-report.txt
```

2. Run benchmarks for a specific token/currency

```sh
# BenchmarksERC20
# BenchmarksERC721
# BenchmarksERC1155
# BenchmarksETH
forge test --mc BenchmarksERC20 --gas-report
```

3. Run benchmarks for a specific contract/solution

```sh
# AirdropClaimMapping
# AirdropClaimMerkle
# AirdropClaimSignature
# Disperse
# wentokens
# GasliteDrop
# BytecodeDrop
# Thirdweb
# ...
forge test --mt AirdropClaimMapping_ERC20 --gas-report
```

4. Run a specific test

```sh
# See the name of each test
forge test --mt test_ERC20_GasliteDrop --gas-report
```

## Disclaimer

> [!WARNING]
> The custom contracts shared in this repository are not meant to be used in production. They are not audited, and some of them are written precisely to showcase how inefficient airdrops can be if not properly designed. This does not only apply to gas consumption, but also to security and usability.
