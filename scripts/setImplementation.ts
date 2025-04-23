import hre from 'hardhat';
import { TokenSettingsStruct } from '../typechain-types/contracts/src/PropositionMarket/PropositionMarketFactory';

const RESET = '\x1b[0m';
const GREEN = '\x1b[32m';

async function main() {
  const { deployer } = await hre.getNamedAccounts();
  console.log('accounts address: ' + `${GREEN}${deployer}${RESET}\n`);

  const { deploy } = hre.deployments;

  const poolContract = await deploy('PropositionMarketPool', {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      Price: '0xb17EDc964596f5eeF7B623AfE0EA259e21e4FD90',
    },
  });
  console.log(poolContract.address);

  const factory = '0x4b9e4e275B5E826aB710DCdEC6071cb3E3Df1532'; // PropositionMarketFactory address
  const factoryContract = await hre.ethers.getContractAt('PropositionMarketFactory', factory); // Specify here your contract name

  const tx = await factoryContract.setImplementation('0x5ce2588A31b37D7a72846349F07409Ce5468664C');
  console.log('The transaction hash is: ' + `${GREEN}${tx.hash}${RESET}\n`);
  console.log('Waiting until the transaction is confirmed...\n');
  const receipt = await tx.wait(); // Wait until the transaction is confirmed
  console.log('The transaction returned the following transaction receipt:\n', receipt);
}

// To run it, invoke `npx hardhat run scripts/interact.ts --network <network_name>`
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
