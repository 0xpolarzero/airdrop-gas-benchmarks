# Gas consumption benchmarks for popular airdrop patterns

This repository contains a series of tests to measure gas usage for popular airdrop patterns with various token standards and airdrop mechanisms. Including:

- native currency (ETH);
- ERC20;
- ERC721;
- ERC1155.

The custom contract ([AirdropClaimMapping.sol](./src/AirdropClaimMapping.sol), and to some extent [AirdropClaimMerkle.sol](./src/AirdropClaimMerkle.sol) and [AirdropClaimSignature.sol](./src/AirdropClaimSignature.sol)) as well, are purposely written poorly to fit common assumptions and patterns found in the wild.

## Table of contents

- [Overview](#overview)
  - [Airdrop mechanisms (custom contracts)](#airdrop-mechanisms-custom-contracts)
  - [Airdrop solutions (including already deployed contracts)](#airdrop-solutions-including-already-deployed-contracts)
- [Results](#results)
  - [ERC20 (direct airdrop)](#erc20-direct-airdrop)
  - [ERC20 (claim-based airdrop)](#erc20-claim-based-airdrop)
  - [ERC721 (direct airdrop)](#erc721-direct-airdrop)
  - [ERC721 (claim-based airdrop)](#erc721-claim-based-airdrop)
  - [ERC1155 (direct airdrop)](#erc1155-direct-airdrop)
  - [ERC1155 (claim-based airdrop)](#erc1155-claim-based-airdrop)
  - [ETH (direct airdrop)](#eth-direct-airdrop)
- [How to run](#how-to-run)
  - [Setup](#setup)
  - [Usage](#usage)

## Overview

### Airdrop mechanisms (custom contracts):

| Type                                              | Tokens                 | Contract                                                     |
| ------------------------------------------------- | ---------------------- | ------------------------------------------------------------ |
| Claimable airdrop (data inscribed into a mapping) | ERC20, ERC721, ERC1155 | [AirdropClaimMapping.sol](./src/AirdropClaimMapping.sol)     |
| Claimable airdrop (merkle proof)                  | ERC20, ERC721, ERC1155 | [AirdropClaimMerkle.sol](./src/AirdropClaimMerkle.sol)       |
| Claimable airdrop (signature)                     | ERC20, ERC721, ERC1155 | [AirdropClaimSignature.sol](./src/AirdropClaimSignature.sol) |
| Airdrop (bytecode contract)                       | ERC20                  | [BytecodeDrop.sol](./src/BytecodeDrop.sol)                   |

### Airdrop solutions (including already deployed contracts):

| Type                                       | Tokens                 | Contract                                         | Website/source code                                  |
| ------------------------------------------ | ---------------------- | ------------------------------------------------ | ---------------------------------------------------- |
| GasliteDrop (airdrop)                      | ETH, ERC20, ERC721     | [GasliteDrop.sol](./src/GasliteDrop.sol)         | [drop.gaslite.org](https://drop.gaslite.org/)        |
| GasliteDrop1155 (airdrop)                  | ERC1155                | [GasliteDrop1155.sol](./src/GasliteDrop1155.sol) | [drop.gaslite.org](https://drop.gaslite.org/)        |
| Disperse.app (airdrop)                     | ETH, ERC20             | [Disperse.sol](./src/Disperse.sol)               | [disperse.app](https://disperse.app/)                |
| wentokens (airdrop)                        | ETH, ERC20             | [Wentokens.sol](./src/Wentokens.sol)             | [www.wentokens.xyz](https://www.wentokens.xyz/)      |
| Thirdweb (airdrop)                         | ERC20, ERC721, ERC1155 | [thirdweb.sol](./src/thirdweb.sol)               | [thirdweb.com](https://thirdweb.com/explore/airdrop) |
| Thirdweb (claimable airdrop, merkle proof) | ERC20, ERC721, ERC1155 | [thirdweb.sol](./src/thirdweb.sol)               | [thirdweb.com](https://thirdweb.com/explore/airdrop) |

---

This Readme is an attempt to showcase the results in an organized and sorted manner.

[!WARNING]
The benchmarks do not include the gas consumption for [the bytecode contract](./src/BytecodeDrop.sol), as [a current limitation with Forge](https://github.com/foundry-rs/foundry/issues/6129); this should actually be the most efficient way for airdropping ERC20 tokens.

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

For **direct airdrops**, the gas cost of deploying and initializing the contract is ignored, as all solutions, excluding Thirdweb, are already deployed and available for use (direct call to the airdrop function).

The cost of deploying and initializing the Thirdweb direct airdrop contracts (`AirdropERC20`, `AirdropERC721`, `AirdropERC1155`) is actually very consistent, so it can be at least mentioned here (with a 1e3 underestimation):

- Deploying proxy: ~66,000 gas
- Initializing proxy: ~144,000

### ERC20 (direct airdrop)

| Rank | Contract                                                     | Gas (1,000 recipients) | Difference from #1 |
| ---- | ------------------------------------------------------------ | ---------------------- | ------------------ |
| 1    | [GasliteDrop](./src//GasliteDrop.sol#L86)                    | 24,946,244             | 0                  |
| 2    | [Wentokens](./src/Wentokens.sol#L77)                         | 24,991,295             | +45,051 (+0.2%)    |
| 3    | [Disperse](./src/Disperse.sol#L20) (`disperseToken`)         | 25,747,105             | +800,861 (+3%)     |
| 4    | [Disperse](./src//Disperse.sol#L31) (`disperseTokenSimple`)  | 26,237,332             | +1,291,088 (+5%)   |
| 5    | [Thirdweb AirdropERC20](./src/thirdweb/AirdropERC20.sol#L96) | 26,906,458             | +1,960,214 (+8%)   |

[!NOTE]
BytecodeDrop is not included yet, but it should be able to be measured consistently against the other contracts with Hardhat.

### ERC20 (claim-based airdrop)

| Rank | Contract                                                                   | Gas deployment (1,000 recipients) | Difference from #1    | Gas claim (1 recipient) | Difference from #1 |
| ---- | -------------------------------------------------------------------------- | --------------------------------- | --------------------- | ----------------------- | ------------------ |
| 1    | [AirdropClaimMerkle](./src/custom/AirdropClaimMerkle_ERC20.sol)            | 381,660 (381,660 + 0)             | 0                     | 51,217                  | 0                  |
| 2    | [AirdropClaimSignature](./src/custom/AirdropClaimSignature_ERC20.sol)      | 410,807 (410,807 + 0)             | +29,147 (+8%)         | 53,376                  | +2,159 (+4%)       |
| 3    | [Thirdweb AirdropERC20Claimable](./src/thirdweb/AirdropERC20Claimable.sol) | 207,525 (66,769 + 140,756)        | -174,135 (-46%)       | 60,563                  | +9,346 (+18%)      |
| 4    | [AirdropClaimMapping](./src/custom/AirdropClaimMapping_ERC20.sol)          | 24,959,529 (450,852 + 24,508,677) | +24,577,869 (+6,440%) | 27,272                  | -23,945 (-47%)     |

This comparison is opinionated. Some arguments to support it:

- The difference in deployment cost is too significant for `AirdropClaimMapping` to be considered a viable solution. Although, in pure gas terms, for 1,000 recipients, it's still cheaper than the Thirdweb and signature-based solutions, i.e. it will spend less gas in total.
- Although the deployment for Thirdweb's `AirdropERC20Claimable` is half the cost of `AirdropClaimMerkle` or `AirdropClaimSignature`, the increase in gas for claiming is too significant to have it ranked higher. I believe that the deployer paying ~200,000 gas instead of ~400,000 can absolutely not justify each single claimer having to pay ~60,000 gas instead of ~50,000.

In any case, these are only benchmarks, with a ranking provided for convenience.

It's also worth noting that Thirdweb does not allow for claiming on behalf of another account, e.g. to sponsor gas fees for a claimer.

### ERC721 (direct airdrop)

| Rank | Contract                                                       | Gas (1,000 recipients) | Difference from #1 |
| ---- | -------------------------------------------------------------- | ---------------------- | ------------------ |
| 1    | [GasliteDrop](./src/GasliteDrop.sol#L46)                       | 27,760,844             | 0                  |
| 2    | [Thirdweb AirdropERC721](./src/thirdweb/AirdropERC721.sol#L93) | 31,028,627             | +3,267,783 (+12%)  |

### ERC721 (claim-based airdrop)

| Rank | Contract                                                                     | Gas deployment (1,000 recipients) | Difference from #1    | Gas claim (1 recipient) | Difference from #1 |
| ---- | ---------------------------------------------------------------------------- | --------------------------------- | --------------------- | ----------------------- | ------------------ |
| 1    | [AirdropClaimMerkle](./src/custom/AirdropClaimMerkle_ERC721.sol)             | 366,041 (366,041 + 0)             | 0                     | 51,897                  | 0                  |
| 2    | [AirdropClaimSignature](./src/custom/AirdropClaimSignature_ERC721.sol)       | 394,994 (394,994 + 0)             | +28,953 (+8%)         | 53,968                  | +2,071 (+4%)       |
| 3    | [AirdropClaimMapping](./src/custom/AirdropClaimMapping_ERC721.sol)           | 31,039,669 (433,833 + 30,605,836) | +30,673,628 (+8,380%) | 28,003                  | -23,894 (-46%%)    |
| 4    | [Thirdweb AirdropERC721Claimable](./src/thirdweb/AirdropERC721Claimable.sol) | 22,452,426 (66,769 + 22,385,657)  | +22,086,385 (+3,034%) | 219,101                 | +167,204 (+322%)   |

It really hurts to not put `AirdropClaimMapping` in the last place, but Thirdweb's `AirdropERC721Claimable` really is too much with both the ~30M gas deployment and the ~218k gas claims. With 1,000 recipients, it is more than 219M in gas just for users to claim their tokens...

Also, `AirdropERC721Claimable` does not allow for airdroping specific tokens to specific accounts, it will just allow to claim `n` amount of tokens, and read the tokenIds array in ascending order. So it basically looks like a minting function.

### ERC1155 (direct airdrop)

| Rank | Contract                                                         | Gas (1,000 recipients) | Difference from #1 |
| ---- | ---------------------------------------------------------------- | ---------------------- | ------------------ |
| 1    | [GasliteDrop1155](./src/GasliteDrop1155.sol#L64)                 | 28,890,255             | 0                  |
| 2    | [Thirdweb AirdropERC1155](./src/thirdweb/AirdropERC1155.sol#L93) | 29,483,628             | +593,373 (+2%)     |

It's worth noting that `GasliteDrop1155` takes advantage of multiple recipients with same amount by packing them into a single struct. Which much better simulates real world scenarios (e.g. users being rewarded the same amounts for the same token IDs after accomplishing a similar task). See:

```solidity
struct AirdropTokenAmount {
    uint256 amount;
    address[] recipients;
}
```

In these tests, there are ~14% of recipients aggregated with the same amount. As the proportion of recipients with the same amount increases, the gap in gas consumption between `GasliteDrop1155` and Thirdweb's `AirdropERC1155` contract will increase as well.

### ERC1155 (claim-based airdrop)

| Rank | Contract                                                                       | Gas deployment (1,000 recipients) | Difference from #1    | Gas claim (1 recipient) | Difference from #1 |
| ---- | ------------------------------------------------------------------------------ | --------------------------------- | --------------------- | ----------------------- | ------------------ |
| 1    | [AirdropClaimMerkle](./src/custom/AirdropClaimMerkle_ERC1155.sol)              | 486,360 (486360 + 0)              | 0                     | 52,873                  | 0                  |
| 2    | [AirdropClaimSignature](./src/custom/AirdropClaimSignature_ERC1155.sol)        | 516,113 (516113 + 0)              | +29,753 (+6%)         | 54,966                  | +2,093 (+4%)       |
| 3    | [Thirdweb AirdropERC1155Claimable](./src/thirdweb/AirdropERC1155Claimable.sol) | 1,556,310 (66769 + 1489541)       | +1,069,950 (+220%)    | 62,083                  | +9,210 (+17%)      |
| 4    | [AirdropClaimMapping](./src/custom/AirdropClaimMapping_ERC1155.sol)            | 27,069,815 (598196 + 26471619)    | +26,583,455 (+5,466%) | 28,995                  | -23,878 (-45%)     |

These contracts allow only for claiming a single token ID per recipient, to fit the Thirdweb pattern.

### ETH (direct airdrop)

| Rank | Contract                                  | Gas (1,000 recipients) | Difference from #1 |
| ---- | ----------------------------------------- | ---------------------- | ------------------ |
| 1    | [GasliteDrop](./src/GasliteDrop.sol#L137) | 34,383,749             | 0                  |
| 2    | [Wentokens](./src/Wentokens.sol#L32)      | 34,437,735             | +53,986 (+0.2%)    |
| 3    | [Disperse](./src/Disperse.sol#L10)        | 34,702,386             | +318,637 (+1%)     |

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
# Benchmarks_ERC20
# Benchmarks_ERC721
# Benchmarks_ERC1155
# Benchmarks_ETH
forge test --mc Benchmarks_ERC20 --gas-report
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
forge test --mt AirdropClaimMapping --gas-report
```

4. Run a specific test

```sh
# See the name of each test
forge test --mt test_ERC20_GasliteDrop --gas-report
```
