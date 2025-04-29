import { data } from '../../args/proposition-market/pmf-args';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { keccak256, stringToBytes } from 'viem';

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function log(msg: string) {
  console.log(`[部署脚本] ${msg}`);
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();
  const contractName = func.tags?.[0] || 'UnknownContract';

  const isTestEnv = process.env.IS_TEST === 'true';
  const mark = isTestEnv ? '测试' : '正式';
  const deploymentSalt = isTestEnv ? `${contractName}_TESTNET` : `${contractName}_MAINNET`;

  const deterministicDeployment = keccak256(stringToBytes(deploymentSalt));

  log(`开始部署 ${mark} 环境合约：${contractName}`);
  log(`当前网络: ${hre.network.name}`);
  log(`部署者地址: ${deployer}`);

  const poolContract = await deploy('PropositionMarketPool', {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      Price: '0x384d2FED6Ce642B8d7dB0454e86b1E662Da2b2DE',
    },
  });

  const tokenContract = await deploy('PropositionMarketToken', {
    from: deployer,
    args: [],
    log: true,
  });

  data[1] = poolContract.address;
  data[2] = tokenContract.address;

  var dataJson = JSON.stringify(data, null, 2);
  log(`参数信息: ${dataJson}`);

  // const contract =
  await deploy(contractName, {
    from: deployer,
    log: true,
    autoMine: true,
    proxy: {
      checkProxyAdmin: false,
      proxyContract: 'ERC1967Proxy',
      proxyArgs: ['{implementation}', '{data}'],
      upgradeFunction: {
        methodName: 'upgradeToAndCall',
        upgradeArgs: ['{implementation}', '{data}'],
      },
      execute: {
        init: {
          methodName: 'initialize',
          args: data,
        },
      },
    },
    deterministicDeployment,
  });

  log('部署完成，等待区块浏览器索引中...');
  await delay(10000);

  //   const encodeData = encodeFunctionData({
  //     abi: contract.abi,
  //     functionName: "initialize",
  //     args: data,
  //   });

  //   try {
  //     await hre.run("verify:verify", {
  //       address: contract.address,
  //       constructorArguments: [contract.address, encodeData],
  //     });
  //     log("合约验证成功");
  //   } catch (error) {
  //     log("⚠️ 合约验证失败，可能原因如下：");
  //     console.error(error);
  //     console.log(`
  // 请尝试手动运行以下命令验证：

  //   npx hardhat verify --network ${hre.network.name} ${contract.implementation}

  // 错误可能提示：构造函数参数数量与提供的不符（如 ${data.length} 个参数但合约定义为 0）。
  //     `);
  //   }
};

func.id = 'deploy_PropositionMarketFactory';
func.tags = ['PropositionMarketFactory'];

export default func;
