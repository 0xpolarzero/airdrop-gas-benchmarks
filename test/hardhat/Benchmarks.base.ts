import { ethers, viem } from 'hardhat';
import { Wallet, Contract, BigNumberish } from 'ethers';
import { loadFixture } from '@nomicfoundation/hardhat-toolbox-viem/network-helpers';
import { MerkleTree } from 'merkletreejs';
import keccak256 from 'keccak256';

// Types
import {
  Mock_ERC20,
  Mock_ERC721,
  AirdropClaimMapping,
  AirdropClaimMerkle,
  AirdropClaimSignature,
  Airdrop as AirdropWentokens,
  GasliteDrop,
  BytecodeDrop,
} from '../../typechain';

export abstract class BenchmarksBase {
  protected erc20: Mock_ERC20;
  protected erc721: Mock_ERC721;
  protected airdropClaimMapping: AirdropClaimMapping;
  protected airdropClaimMerkle: AirdropClaimMerkle;
  protected airdropClaimSignature: AirdropClaimSignature;
  protected airdropWentokens: AirdropWentokens;
  protected gasliteDrop: GasliteDrop;
  protected bytecodeDrop: BytecodeDrop;

  protected recipients: Wallet[] = [];
  protected amounts: BigNumber[] = [];
  protected totalAmount: BigNumber = BigNumber.from(0);
  protected tokenIds: BigNumber[] = [];

  protected rootERC20: string;
  protected rootERC721: string;
  protected dataERC20: string[] = [];
  protected dataERC721: string[] = [];

  protected signer: Wallet;
  protected signerKey: string;

  protected NUM_RECIPIENTS: number = 1000; // Set the number of recipients

  constructor() {
    this.setup();
  }

  protected async setup(): Promise<void> {
    this.generate();
    const { erc20 } = await loadFixture(this.deploy);
    this.erc20 = erc20;
  }

  protected async deploy() {
    // Deploy contracts
    const erc20 = await viem.deployContract('Mock_ERC20', [this.totalAmount]);
    this.erc20 = erc20;

    return { erc20 };

    // const [
    //   airdropClaimMapping,
    //   airdropClaimMerkle,
    //   airdropClaimSignature,
    //   airdropWentokens,
    //   gasliteDrop,
    //   bytecodeDrop,
    // ] = await Promise.all([
    //   ethers.deployContract('AirdropClaimMapping', [erc20, erc721]),
    //   ethers.deployContract('AirdropClaimMerkle', [
    //     erc20,
    //     erc721,
    //     this.rootERC20,
    //     this.rootERC721,
    //   ]),
    //   ethers.deployContract('AirdropClaimSignature', [
    //     erc20,
    //     erc721,
    //     this.signer,
    //   ]),
    //   ethers.deployContract('AirdropWentokens'),
    //   ethers.deployContract('GasliteDrop'),
    //   ethers.deployContract('BytecodeDrop'),
    // ]);

    // // Set contract variables
    // this.erc20 = erc20;
    // this.erc721 = erc721;
  }

  protected generate() {}

  private generateRandomData() {
    // Generate random data
    for (let i = 0; i < this.NUM_RECIPIENTS; i++) {
      this.recipients.push(Wallet.createRandom());
      this.amounts.push(BigNumber.from((Math.random() * 1e19).toFixed(0))); // Example random amount
      this.totalAmount = this.totalAmount.add(this.amounts[i]);
      this.tokenIds.push(BigNumber.from(i));
    }
  }

  private generateMerkleData() {
    // Generate Merkle tree data
    this.dataERC20 = this.recipients.map((recipient, index) =>
      keccak256(
        ethers.utils.defaultAbiCoder.encode(
          ['address', 'uint256'],
          [recipient.address, this.amounts[index]],
        ),
      ),
    );

    this.dataERC721 = this.recipients.map((recipient, index) =>
      keccak256(
        ethers.utils.defaultAbiCoder.encode(
          ['address', 'uint256'],
          [recipient.address, this.tokenIds[index]],
        ),
      ),
    );

    this.rootERC20 = this.createMerkleTree(this.dataERC20)
      .getRoot()
      .toString('hex');
    this.rootERC721 = this.createMerkleTree(this.dataERC721)
      .getRoot()
      .toString('hex');
  }

  private createMerkleTree(elements: string[]): MerkleTree {
    return new MerkleTree(elements, keccak256, { sortPairs: true });
  }

  protected getMerkleProof(tree: MerkleTree, index: number) {
    return tree.getHexProof(tree.getLeaves()[index]);
  }

  protected async randomSigner() {
    // Generate a random signer
    this.signer = Wallet.createRandom();
    this.signerKey = this.signer.privateKey;
  }
}
