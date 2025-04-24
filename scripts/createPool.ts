import hre from 'hardhat';
import { TokenSettingsStruct } from '../typechain-types/contracts/src/PropositionMarket/PropositionMarketFactory';

const RESET = '\x1b[0m';
const GREEN = '\x1b[32m';

async function main() {
  const { deployer } = await hre.getNamedAccounts();
  console.log('accounts address: ' + `${GREEN}${deployer}${RESET}\n`);

  const factory = '0x2e67fe1480c83ee0e49452f1d51ba82798c71a99'; // PropositionMarketFactory address
  const factoryContract = await hre.ethers.getContractAt('PropositionMarketFactory', factory); // Specify here your contract name

  const tokenSettings: TokenSettingsStruct[] = [
    {
      owner: factory,
      name: 'love blackpink',
      symbol: 'BLACK',
    },
    {
      owner: factory,
      name: 'love bts',
      symbol: 'BTS',
    },
  ];
  const poolTitle = 'BLACK VS BTS Two';
  const payToken = '0x163aC8C09D41a6Dc90EbF95dCb767D9aDb469f7e';

  const tx = await factoryContract.createContracts(tokenSettings, poolTitle, payToken);
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
