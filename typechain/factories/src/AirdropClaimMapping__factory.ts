/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  Contract,
  ContractFactory,
  ContractTransactionResponse,
  Interface,
} from "ethers";
import type {
  Signer,
  AddressLike,
  ContractDeployTransaction,
  ContractRunner,
} from "ethers";
import type { NonPayableOverrides } from "../../common";
import type {
  AirdropClaimMapping,
  AirdropClaimMappingInterface,
} from "../../src/AirdropClaimMapping";

const _abi = [
  {
    inputs: [
      {
        internalType: "contract ERC20",
        name: "_tokenERC20",
        type: "address",
      },
      {
        internalType: "contract ERC721",
        name: "_tokenERC721",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [],
    name: "AirdropClaimMapping_MismatchedArrays",
    type: "error",
  },
  {
    inputs: [],
    name: "AirdropClaimMapping_NothingToClaim",
    type: "error",
  },
  {
    inputs: [],
    name: "AirdropClaimMapping_TransferFailed",
    type: "error",
  },
  {
    inputs: [],
    name: "AlreadyInitialized",
    type: "error",
  },
  {
    inputs: [],
    name: "NewOwnerIsZeroAddress",
    type: "error",
  },
  {
    inputs: [],
    name: "NoHandoverRequest",
    type: "error",
  },
  {
    inputs: [],
    name: "Unauthorized",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "recipient",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "AirdroppedERC20",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "recipient",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "AirdroppedERC721",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "recipient",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "ClaimedERC20",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "recipient",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "ClaimedERC721",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "pendingOwner",
        type: "address",
      },
    ],
    name: "OwnershipHandoverCanceled",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "pendingOwner",
        type: "address",
      },
    ],
    name: "OwnershipHandoverRequested",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "oldOwner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnershipTransferred",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address[]",
        name: "_recipients",
        type: "address[]",
      },
      {
        internalType: "uint256[]",
        name: "_amounts",
        type: "uint256[]",
      },
    ],
    name: "airdropERC20",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address[]",
        name: "_recipients",
        type: "address[]",
      },
      {
        internalType: "uint256[]",
        name: "_tokenIds",
        type: "uint256[]",
      },
    ],
    name: "airdropERC721",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "allowed_erc721",
    outputs: [
      {
        internalType: "bool",
        name: "canClaim",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "balances_erc20",
    outputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "balances_erc721",
    outputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "cancelOwnershipHandover",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "claimERC20",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "claimERC721",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "pendingOwner",
        type: "address",
      },
    ],
    name: "completeOwnershipHandover",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "erc20",
    outputs: [
      {
        internalType: "contract ERC20",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "erc721",
    outputs: [
      {
        internalType: "contract ERC721",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "owner",
    outputs: [
      {
        internalType: "address",
        name: "result",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "pendingOwner",
        type: "address",
      },
    ],
    name: "ownershipHandoverExpiresAt",
    outputs: [
      {
        internalType: "uint256",
        name: "result",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "renounceOwnership",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "requestOwnershipHandover",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "transferOwnership",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b50604051610d14380380610d1483398101604081905261002f916100c1565b600080546001600160a01b038085166001600160a01b03199283161790925560018054928416929091169190911790556100683361006f565b50506100fb565b6001600160a01b0316638b78c6d8198190558060007f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e08180a35b50565b6001600160a01b03811681146100a957600080fd5b600080604083850312156100d457600080fd5b82516100df816100ac565b60208401519092506100f0816100ac565b809150509250929050565b610c0a8061010a6000396000f3fe6080604052600436106100f35760003560e01c8063971db7701161008a578063dfdbf41f11610059578063dfdbf41f1461027a578063f04e283e1461029a578063f2fde38b146102ad578063fee81cf4146102c057600080fd5b8063971db770146101cd578063a3b86230146101fa578063bca6ce641461021a578063d14c07761461023a57600080fd5b806354d1f13d116100c657806354d1f13d1461016c578063715018a614610174578063785e9e861461017c5780638da5cb5b146101b457600080fd5b806303e4ecb8146100f8578063256929621461010f5780633fbd69cd146101175780634b1669601461012c575b600080fd5b34801561010457600080fd5b5061010d6102f3565b005b61010d6103ee565b34801561012357600080fd5b5061010d61043e565b34801561013857600080fd5b50610159610147366004610a6c565b60036020526000908152604090205481565b6040519081526020015b60405180910390f35b61010d610544565b61010d610580565b34801561018857600080fd5b5060005461019c906001600160a01b031681565b6040516001600160a01b039091168152602001610163565b3480156101c057600080fd5b50638b78c6d8195461019c565b3480156101d957600080fd5b506101596101e8366004610a6c565b60026020526000908152604090205481565b34801561020657600080fd5b5061010d610215366004610ae8565b610594565b34801561022657600080fd5b5060015461019c906001600160a01b031681565b34801561024657600080fd5b5061026a610255366004610a6c565b60046020526000908152604090205460ff1681565b6040519015158152602001610163565b34801561028657600080fd5b5061010d610295366004610ae8565b61079a565b61010d6102a8366004610a6c565b6109ac565b61010d6102bb366004610a6c565b6109ec565b3480156102cc57600080fd5b506101596102db366004610a6c565b63389a75e1600c908152600091909152602090205490565b3360009081526003602090815260408083205460049092529091205460ff1661032f5760405163f953203160e01b815260040160405180910390fd5b33600081815260046020819052604091829020805460ff1916905560015491516323b872dd60e01b815230918101919091526024810192909252604482018390526001600160a01b0316906323b872dd90606401600060405180830381600087803b15801561039d57600080fd5b505af11580156103b1573d6000803e3d6000fd5b50506040518381523392507f81b2ae614b1876f030c9dab3e9d8301926fbb2baba7dd8169b7ea149acc1b72a91506020015b60405180910390a250565b60006202a30067ffffffffffffffff164201905063389a75e1600c5233600052806020600c2055337fdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d600080a250565b336000908152600260205260408120549081900361046f5760405163f953203160e01b815260040160405180910390fd5b336000818152600260205260408082208290559054905163a9059cbb60e01b81526004810192909252602482018390526001600160a01b03169063a9059cbb906044016020604051808303816000875af11580156104d1573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906104f59190610b54565b61051257604051633a4693dd60e21b815260040160405180910390fd5b60405181815233907fc738b2de230010873d5b81370b4c10250e8eaec27550f0c43faf979e09309083906020016103e3565b63389a75e1600c523360005260006020600c2055337ffa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92600080a2565b610588610a13565b6105926000610a2e565b565b61059c610a13565b8281146105bc5760405163534d4b4960e11b815260040160405180910390fd5b6000805b848110156106fa578383828181106105da576105da610b76565b90506020020135600260008888858181106105f7576105f7610b76565b905060200201602081019061060c9190610a6c565b6001600160a01b03166001600160a01b03168152602001908152602001600020600082825461063b9190610ba2565b90915550849050838281811061065357610653610b76565b90506020020135826106659190610ba2565b915085858281811061067957610679610b76565b905060200201602081019061068e9190610a6c565b6001600160a01b03167fc6476c4f33ae21b81db4597ffaad583337ae0b064e6679e0e382021096e039548585848181106106ca576106ca610b76565b905060200201356040516106e091815260200190565b60405180910390a2806106f281610bbb565b9150506105c0565b506000546040516323b872dd60e01b8152336004820152306024820152604481018390526001600160a01b03909116906323b872dd906064016020604051808303816000875af1158015610752573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906107769190610b54565b61079357604051633a4693dd60e21b815260040160405180910390fd5b5050505050565b6107a2610a13565b8281146107c25760405163534d4b4960e11b815260040160405180910390fd5b60005b83811015610793578282828181106107df576107df610b76565b90506020020135600360008787858181106107fc576107fc610b76565b90506020020160208101906108119190610a6c565b6001600160a01b03166001600160a01b031681526020019081526020016000208190555060016004600087878581811061084d5761084d610b76565b90506020020160208101906108629190610a6c565b6001600160a01b0390811682526020820192909252604001600020805460ff191692151592909217909155600154166323b872dd33308686868181106108aa576108aa610b76565b6040516001600160e01b031960e088901b1681526001600160a01b03958616600482015294909316602485015250602090910201356044820152606401600060405180830381600087803b15801561090157600080fd5b505af1158015610915573d6000803e3d6000fd5b5050505084848281811061092b5761092b610b76565b90506020020160208101906109409190610a6c565b6001600160a01b03167fd13b368daf3c9e99665c93202435b1e3b564bef945b18324d678f412d949783884848481811061097c5761097c610b76565b9050602002013560405161099291815260200190565b60405180910390a2806109a481610bbb565b9150506107c5565b6109b4610a13565b63389a75e1600c52806000526020600c2080544211156109dc57636f5e88186000526004601cfd5b600090556109e981610a2e565b50565b6109f4610a13565b8060601b610a0a57637448fbae6000526004601cfd5b6109e981610a2e565b638b78c6d819543314610592576382b429006000526004601cfd5b638b78c6d81980546001600160a01b039092169182907f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0600080a355565b600060208284031215610a7e57600080fd5b81356001600160a01b0381168114610a9557600080fd5b9392505050565b60008083601f840112610aae57600080fd5b50813567ffffffffffffffff811115610ac657600080fd5b6020830191508360208260051b8501011115610ae157600080fd5b9250929050565b60008060008060408587031215610afe57600080fd5b843567ffffffffffffffff80821115610b1657600080fd5b610b2288838901610a9c565b90965094506020870135915080821115610b3b57600080fd5b50610b4887828801610a9c565b95989497509550505050565b600060208284031215610b6657600080fd5b81518015158114610a9557600080fd5b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052601160045260246000fd5b80820180821115610bb557610bb5610b8c565b92915050565b600060018201610bcd57610bcd610b8c565b506001019056fea2646970667358221220ceb3850a65c7d1d9efc98bb5fd4ade36955b09d9b3810f675a8d0b7a49bc398e64736f6c63430008140033";

type AirdropClaimMappingConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: AirdropClaimMappingConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class AirdropClaimMapping__factory extends ContractFactory {
  constructor(...args: AirdropClaimMappingConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override getDeployTransaction(
    _tokenERC20: AddressLike,
    _tokenERC721: AddressLike,
    overrides?: NonPayableOverrides & { from?: string }
  ): Promise<ContractDeployTransaction> {
    return super.getDeployTransaction(
      _tokenERC20,
      _tokenERC721,
      overrides || {}
    );
  }
  override deploy(
    _tokenERC20: AddressLike,
    _tokenERC721: AddressLike,
    overrides?: NonPayableOverrides & { from?: string }
  ) {
    return super.deploy(_tokenERC20, _tokenERC721, overrides || {}) as Promise<
      AirdropClaimMapping & {
        deploymentTransaction(): ContractTransactionResponse;
      }
    >;
  }
  override connect(
    runner: ContractRunner | null
  ): AirdropClaimMapping__factory {
    return super.connect(runner) as AirdropClaimMapping__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): AirdropClaimMappingInterface {
    return new Interface(_abi) as AirdropClaimMappingInterface;
  }
  static connect(
    address: string,
    runner?: ContractRunner | null
  ): AirdropClaimMapping {
    return new Contract(
      address,
      _abi,
      runner
    ) as unknown as AirdropClaimMapping;
  }
}
