import { HardhatUserConfig, task } from "hardhat/config";

import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-verify";
import "@nomicfoundation/hardhat-ledger";
import "@nomicfoundation/hardhat-foundry";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-ignition-ethers";
import "@typechain/hardhat";
import "hardhat-deploy";

import "xdeployer";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-verify";
import "@matterlabs/hardhat-zksync-ethers";
// 如果要使用 Truffle Dashboard 模块，请取消注释
// 您还必须相应地取消注释此文件中后续的 `truffle` 配置
// import "@truffle/dashboard-hardhat-plugin";
import "hardhat-gas-reporter";
import "hardhat-abi-exporter";
import "solidity-coverage";
import "hardhat-contract-sizer";
// 如果要使用 Hardhat Tenderly 模块，请取消注释
// 您还必须相应地取消注释此文件中后续的“tenderly”配置
import "@tenderly/hardhat-tenderly";
import dotenv from "dotenv";

dotenv.config();

const ethMainnetUrl = `https://rpc.ankr.com/eth/${process.env.ANKR_API_KEY as string}`;
const forkingUrl = (process.env.FORKING_URL as string) || ethMainnetUrl;
const account = process.env.ACCOUNT as string;
const privateKey = [process.env.PRIVATE_KEY as string];

const ledgerAccounts = ["0x8195fa8224c39103f578c9b84f951721df3fa71c"];

task("accounts", "Prints the list of accounts", async (_, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task("evm", "Prints the configured EVM version", async (_, hre) => {
  console.log(hre.config.solidity.compilers[0].settings.evmVersion);
});

task(
  "balances",
  "Prints the list of accounts and their balances",
  async (_, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
      console.log(
        account.address +
          " " +
          (await hre.ethers.provider.getBalance(account.address)),
      );
    }
  },
);

const config: HardhatUserConfig = {
  paths: {
    sources: "./contracts/src",
  },
  solidity: {
    // 仅对支持新 `cancun` 操作码的 EVM 网络使用 Solidity 默认版本 `>=0.8.25`:
    // https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/cancun.md
    // 仅对支持操作码 `PUSH0` 的 EVM 网络使用 Solidity 默认版本 `>=0.8.20`
    // 否则，使用版本 `<=0.8.19`
    version: "0.8.23",
    settings: {
      optimizer: {
        enabled: true,
        runs: 999_999,
      },
      evmVersion: "paris", // 防止使用“PUSH0”和“cancun”操作码
    },
  },
  zksolc: {
    version: "1.5.12",
    compilerSource: "binary",
    settings: {
      enableEraVMExtensions: false,
      forceEVMLA: false,
      optimizer: {
        enabled: true,
        mode: "3",
        fallback_to_optimizing_for_size: false,
      },
    },
  },
  // // 如果要使用 Truffle Dashboard 模块，请取消注释
  // truffle: {
  //   dashboardNetworkName: "truffleDashboard", // Truffle 的默认值是“truffleDashboard”
  //   dashboardNetworkConfig: {
  //     // Truffle 的默认值为 0（即无超时），而 Hardhat 的默认值为 40000（40 秒）
  //     timeout: 0,
  //   },
  // },
  namedAccounts: {
    deployer: {
      metis: account,
      hardhat: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      localhost: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
      goerli: account,
      ethMain: account,
      bscTestnet: account,
      bscMain: account,
    },
  },
  networks: {
    hardhat: {
      initialBaseFeePerGas: 0,
      chainId: 31337,
      hardfork: "cancun",
      accounts: {
        mnemonic: "test test test test test test test test test test test junk", // 可选自定义
      },
      forking: {
        url: forkingUrl,
        // Hardhat 网络将默认从最新的主网区块分叉
        // 要固定区块编号，请在下面指定
        // 您需要访问具有存档数据的节点才能使其工作！
        // blockNumber: 14743877,
        // 如果您想进行一些分叉，请将“enabled”设置为 true
        enabled: true,
      },
      ledgerAccounts,
      // zksync: true, // Enable ZKsync in the Hardhat local network
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      accounts: privateKey,
    },
    tenderly: {
      // Add your own Tenderly fork ID
      url: `https://rpc.tenderly.co/fork/${process.env.TENDERLY_FORK_ID as string}`,
      accounts: privateKey,
    },
    devnet: {
      // Add your own Tenderly DevNet ID
      url: `https://rpc.vnet.tenderly.co/devnet/${process.env.TENDERLY_DEVNET_ID as string}`,
      accounts: privateKey,
      ledgerAccounts,
    },
    goerli: {
      chainId: 5,
      url:
        (process.env.ETH_GOERLI_TESTNET_URL as string) ||
        "https://rpc.ankr.com/eth_goerli",
      accounts: privateKey,
      ledgerAccounts,
    },
    sepolia: {
      chainId: 11155111,
      url:
        (process.env.ETH_SEPOLIA_TESTNET_URL as string) ||
        "https://rpc.sepolia.org",
      accounts: privateKey,
      ledgerAccounts,
    },
    ethMain: {
      chainId: 1,
      url: ethMainnetUrl,
      accounts: privateKey,
      ledgerAccounts,
    },
    bscTestnet: {
      chainId: 97,
      url: process.env.BSC_TESTNET_URL as string,
      accounts: privateKey,
      ledgerAccounts,
    },
    bscMain: {
      chainId: 56,
      url: process.env.BSC_MAINNET_URL as string,
      accounts: privateKey,
      ledgerAccounts,
    },
  },
  xdeploy: {
    // 将此名称更改为您的主合约的名称
    // 不一定必须与合约文件名匹配
    contract: "",
    // 如果构造函数没有任何输入参数，则更改为“undefined”
    constructorArgsPath: "",
    // 对于每个想要拥有单个合约地址的 EVM 链，盐值必须相同
    // 如果使用相同的代码库进行重新部署，请更改盐值
    salt:
      (process.env.XDEPLOY_SALT as string) ||
      "0x00000000000000000000000000000000",
    // 这是你的钱包的私钥
    signer: privateKey,
    // 使用此处指定的网络名称：https://github.com/pcaversaccio/xdeployer#configuration
    // 使用“localhost”或“hardhat”进行本地测试
    networks: ["hardhat", "sepolia", "optimismSepolia"],

    // 在 `.env` 文件中使用与您选择的 RPC 匹配的 env URL
    rpcUrls: [
      "hardhat",
      (process.env.ETH_SEPOLIA_TESTNET_URL as string) ||
        "https://rpc.sepolia.org",
      (process.env.OPTIMISM_SEPOLIA_URL as string) ||
        "https://sepolia.optimism.io",
    ],

    // 最大限制为 15 * 10 ** 6 或 15,000,000。如果部署失败，请尝试增加此数字
    // 但是，请记住，这在生产环境中需要花钱！
    gasLimit: 1.2 * 10 ** 6,
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
    strict: true,
    only: [],
    except: ["CreateX", "Create2DeployerLocal"],
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS as unknown as boolean,
    currency: "USD",
  },
  abiExporter: {
    path: "./abis",
    runOnCompile: true,
    clear: true,
    flat: false,
    only: [],
    spacing: 2,
    pretty: true,
  },
  sourcify: {
    // 默认启用 Sourcify 验证
    enabled: false,
    apiUrl: "https://sourcify.dev/server",
    browserUrl: "https://repo.sourcify.dev",
  },
  blockscout: {
    // 默认禁用 Blockscout 验证
    // 如果需要，您可以使用 `etherscan` 配置中的 `customChains` 属性来添加更多链
    enabled: false,
  },
  etherscan: {
    // 通过在 etherscan (https://etherscan.io)、snowtrace (https://snowtrace.io) 等处获取帐户来添加您自己的 API 密钥。
    // 当您想使用 Hardhat 对合约进行“npx hardhat verify”时，这可用于验证目的
    // 相同的 API 密钥通常适用于测试网和主网
    apiKey: {
      // For Ethereum testnets & mainnet
      mainnet: process.env.ETHERSCAN_API_KEY as string,
      goerli: process.env.ETHERSCAN_API_KEY as string,
      sepolia: process.env.ETHERSCAN_API_KEY as string,
      holesky: process.env.ETHERSCAN_API_KEY as string,
      // For BSC testnet & mainnet
      bsc: process.env.BSC_API_KEY as string,
      bscTestnet: process.env.BSC_API_KEY as string,
    },
    // 定制链
    customChains: [],
  },
  external: {
    contracts: [
      {
        artifacts:
          "node_modules/@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol/",
      },
    ],
  },
  // tenderly: {
  //   username: "MyAwesomeUsername",
  //   project: "super-awesome-project",
  //   forkNetwork: "",
  //   privateVerification: false,
  //   deploymentsDir: "deployments_tenderly",
  // },
};

export default config;
