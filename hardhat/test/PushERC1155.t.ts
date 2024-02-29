import { loadFixture } from '@nomicfoundation/hardhat-toolbox-viem/network-helpers';
import { viem } from 'hardhat';
import { Address, Hex } from 'viem';
import { generatePrivateKey, privateKeyToAddress } from 'viem/accounts';

const { deployContract, getContractAt, getPublicClient, getWalletClients } =
  viem;

/* -------------------------------------------------------------------------- */
/*                                    TYPES                                   */
/* -------------------------------------------------------------------------- */

/* ------------------------------ AIRDROP DATA ------------------------------ */
// Airdrop data
type AirdropData = {
  recipients: Address[];
  ids: bigint[];
  amounts: bigint[];
};

// Thirdweb airdrop data
type AirdropContent = {
  recipient: Address;
  tokenId: bigint;
  amount: bigint;
};

// Gaslite airdrop data
type AirdropToken = {
  tokenId: bigint;
  airdropAmounts: {
    amount: bigint;
    recipients: Address[];
  }[];
};

/* ------------------------------ AIRDROP ARGS ------------------------------ */
// Thirdweb
type AirdropArgsThirdweb = [Address, Address, AirdropContent[]];

// Gaslite
type AirdropArgsGaslite = [Address, AirdropToken[]];

/* ---------------------------- FORMAT FUNCTIONS ---------------------------- */
// Thirdweb
type FormatAirdropDataThirdweb = (
  airdropData: AirdropData,
  tokenAddress: Address,
  tokenOwner: Address
) => AirdropArgsThirdweb;

// Gaslite
type FormatAirdropDataGaslite = (
  airdropData: AirdropData,
  tokenAddress: Address
) => AirdropArgsGaslite;

/* -------------------------------------------------------------------------- */
/*                                  CONSTANTS                                 */
/* -------------------------------------------------------------------------- */

// How many recipients to airdrop to
const NUM_RECIPIENTS = 1000;
// The ids to airdrop [0, NUM_IDS - 1]
const NUM_IDS = 10;
const IDS = Array.from({ length: NUM_IDS }, (_, i) => BigInt(i));
// The min/max amount to airdrop
const MIN_AMOUNT = BigInt(1e13);
const MAX_AMOUNT = BigInt(1e19);

// Entropy levels to test
const ENTROPY_LEVELS = [5, 10, 20, 50, 80, 100];

/* -------------------------------------------------------------------------- */
/*                                    TEST                                    */
/* -------------------------------------------------------------------------- */

describe('PushERC1155', function () {
  // Deploy a mock ERC1155, airdrop contracts, and prepare airdrop function
  const deployMockAndContractFixture = async () => {
    /* -------------------------------- PROVIDERS ------------------------------- */
    /* --------------------------------- PREPARE -------------------------------- */
    const publicClient = await getPublicClient();
    const [deployer] = await getWalletClients();

    // Deploy contracts
    const mockERC1155 = await deployContract('MockERC1155', [
      // Mint the max amount * all recipients for each id
      IDS,
      Array.from(
        { length: NUM_IDS },
        () => BigInt(NUM_RECIPIENTS) * MAX_AMOUNT
      ),
    ]);

    /* -------------------------------- THIRDWEB -------------------------------- */
    // Deploy proxy factory
    const erc1967Factory = await deployContract('ERC1967Factory');
    // Deploy implementation
    const airdropERC1155Implementation = await deployContract('AirdropERC1155');
    // Predict the address of the proxy
    const salt = `${deployer.account.address}${'1'.repeat(64 - 40)}` as Hex;
    const proxyAddress = await erc1967Factory.read.predictDeterministicAddress([
      salt,
    ]);
    // Deploy proxy
    await erc1967Factory.write.deployDeterministic([
      airdropERC1155Implementation.address,
      deployer.account.address,
      salt,
    ]);
    // Retrieve the proxy instance as the implementation
    const airdropERC1155 = await getContractAt('AirdropERC1155', proxyAddress);
    // [default admin, contract uri, trusted forwarders]
    await airdropERC1155.write.initialize([deployer.account.address, '', []]);

    /* -------------------------------- GASELITE -------------------------------- */
    const gasliteDrop1155 = await deployContract('GasliteDrop1155');

    /* -------------------------------- FUNCTIONS ------------------------------- */
    // Create a function to airdrop with both contracts and return the gas used
    const airdropAndReturnGasUsed = async (airdropData: {
      recipients: Address[];
      ids: bigint[];
      amounts: bigint[];
    }): Promise<bigint[]> => {
      const contracts = [
        {
          instance: airdropERC1155,
          format: formatAirdropDataThirdweb,
        },
        {
          instance: gasliteDrop1155,
          format: formatAirdropDataGaslite,
        },
      ];
      // Approve
      await Promise.all(
        contracts.map(({ instance }) =>
          mockERC1155.write.setApprovalForAll([instance.address, true])
        )
      );

      // Airdrop
      const txHashes = await Promise.all(
        contracts.map(({ instance, format }) => {
          const formattedData = format(
            airdropData,
            mockERC1155.address,
            deployer.account.address
          );
          if (instance === airdropERC1155) {
            return instance.write.airdropERC1155(
              formattedData as AirdropArgsThirdweb
            );
          } else if (instance === gasliteDrop1155) {
            return instance.write.airdropERC1155(
              formattedData as AirdropArgsGaslite
            );
          }

          return '0x';
        })
      );

      // Get gas used
      return await Promise.all(
        txHashes.map(async (hash: Hex) => {
          const receipt = await publicClient.waitForTransactionReceipt({
            hash,
          });
          return receipt.gasUsed;
        })
      );
    };

    return { airdropAndReturnGasUsed };
  };

  describe('airdropERC1155', function () {
    it('call with various entropy levels', async function () {
      // Remember the gas used for each entropy level
      // { entropy: { contract: gasUsed }, ... }
      let gasUsedForEntropy: Record<string, Record<string, string>> = {};

      // Loop through entropy levels
      for (const entropy of ENTROPY_LEVELS) {
        // Deploy
        const { airdropAndReturnGasUsed } = await loadFixture(
          deployMockAndContractFixture
        );

        // Prepare, airdrop and return gas used
        const gasUsed = await airdropAndReturnGasUsed(
          generateRandomAirdropData(entropy) // 5% entropy
        );

        // Save gas used
        gasUsedForEntropy = {
          ...gasUsedForEntropy,
          [`${entropy}%`]: {
            'Thirdweb AirdropERC1155': toReadableNumber(gasUsed[0]),
            GasliteDrop1155: toReadableNumber(gasUsed[1]),
          },
        };
      }

      // Log gas used
      console.table(gasUsedForEntropy);
    });
  });
});

/* -------------------------------------------------------------------------- */
/*                                  UTILITIES                                 */
/* -------------------------------------------------------------------------- */

/* ------------------------------- RANDOM DATA ------------------------------ */
// Generate random airdrop data for the given entropy
const generateRandomAirdropData = (entropy: number): AirdropData => {
  // Get random addresses
  const recipients = Array.from({ length: NUM_RECIPIENTS }, () =>
    privateKeyToAddress(generatePrivateKey())
  );

  // Get random ids
  const ids = Array.from({ length: NUM_RECIPIENTS }, () =>
    BigInt(Math.floor(Math.random() * NUM_IDS))
  );

  // 1. Generate temporary random amounts for each recipient
  let preliminaryAmounts = Array.from({ length: NUM_RECIPIENTS }, () =>
    randomAmount()
  );

  // 2. Modify amounts based on the entropy
  const amounts = preliminaryAmounts.map((amount, index) => {
    // <entropy>% of the time, try to reuse an amount already used for that id
    const reuse = Math.random() < entropy / 100;
    if (reuse) {
      // Find another amount used for the same id, if available
      const sameIdIndex = ids.findIndex(
        (id, i) => id === ids[index] && i !== index
      );
      return sameIdIndex !== -1 ? preliminaryAmounts[sameIdIndex] : amount;
    }
    return amount;
  });

  return { recipients, ids, amounts };
};

// Generate a random amount between MIN_AMOUNT and MAX_AMOUNT
const randomAmount = () =>
  MIN_AMOUNT +
  BigInt(Math.floor(Math.random() * (Number(MAX_AMOUNT) - Number(MIN_AMOUNT))));

/* ------------------------------- FORMATTING ------------------------------- */
// Format airdrop data for Thirdweb AirdropERC1155
// [address _tokenAddress, address _tokenOwner, AirdropContent[] calldata _contents]
// with AirdropContent = {address recipient, uint256 tokenId, uint256 amount}
const formatAirdropDataThirdweb: FormatAirdropDataThirdweb = (
  { recipients, ids, amounts },
  tokenAddress,
  tokenOwner
) => [
  tokenAddress,
  tokenOwner,
  recipients.map((recipient, i) => ({
    recipient,
    tokenId: ids[i],
    amount: amounts[i],
  })),
];

// Format airdrop data for Gaslite AirdropERC1155
// [address _tokenAddress, AirdropToken[] calldata airdropTokens]
// with AirdropToken = {uint256 tokenId, AirdropTokenAmount[] airdropAmounts}
// with AirdropTokenAmount = {uint256 amount, address[] recipients}
// This takes advantage of the realistic fact that in most cases multiple recipients will
// be airdropped the same amount of the same token id; which get packed for maximum efficiency
const formatAirdropDataGaslite: FormatAirdropDataGaslite = (
  { recipients, ids, amounts },
  tokenAddress
) => {
  // Group amounts and recipients by id
  const airdropTokens: AirdropToken[] = Array.from(
    { length: NUM_IDS },
    (_, i) => BigInt(i)
  ).map((id) => {
    const airdropAmounts: AirdropToken['airdropAmounts'] = [];
    // For each recipient, add their amount to the corresponding id
    recipients.forEach((recipient, i) => {
      if (ids[i] === id) {
        const amount = amounts[i];
        // Find the airdropAmounts for this amount
        let airdropAmount = airdropAmounts.find(
          (a) => a.amount === amount
        ) as AirdropToken['airdropAmounts'][0];
        // If it doesn't exist, create it
        if (!airdropAmount) {
          airdropAmount = { amount, recipients: [] };
          airdropAmounts.push(airdropAmount);
        }
        // Add the recipient to the airdropAmount
        airdropAmount.recipients.push(recipient);
      }
    });
    return { tokenId: id, airdropAmounts };
  });

  return [tokenAddress, airdropTokens];
};

/* -------------------------------------------------------------------------- */
// Format to a readable number with commas
const toReadableNumber = (num: bigint) =>
  num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
